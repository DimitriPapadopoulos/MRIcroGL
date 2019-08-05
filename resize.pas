unit resize;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Math,
  nifti_types, SimdUtils, VectorMath;

type

  { TResizeForm }

  TResizeForm = class(TForm)
    AllVolumesCheck: TCheckBox;
    FilterDrop: TComboBox;
    DataTypeDrop: TComboBox;
    IsotropicBtn: TButton;
    IsotropicShrinkBtn: TButton;
    OKBtn: TButton;
    CancelBtn: TButton;
    ChangeLabel: TLabel;
    XEdit: TEdit;
    InLabel: TLabel;
    YEdit: TEdit;
    ZEdit: TEdit;
    ZLabel: TLabel;
    YLabel: TLabel;
    XLabel: TLabel;
    OutLabel: TLabel;
    InterpLabel: TLabel;
    DataTypeLabel: TLabel;
    procedure EditChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure IsotropicBtnClick(Sender: TObject);
    procedure IsotropicShrinkBtnClick(Sender: TObject);
    function ReadScale(): TVec3;
  private

  public
    function GetScale(hdr: TNIFTIhdr; isLabel: boolean; filename: string; out datatype: integer;  out Filter: integer; out isAllVolumes: boolean): TVec3;

    //function GetScale(hdr: TNIFTIhdr; filename: string; out datatype: integer;  out Filter: integer): TVec3;
    //function GetScale(const Dim: TVec3i; const mm: TVec3; filename: string; var datatype: integer;  out Filter: integer): TVec3;
  end;

var
  ResizeForm: TResizeForm;

implementation

{$R *.lfm}
var
  gDim: TVec3i;
  gMM: TVec3;
  gBPP: integer;

{ TResizeForm }
function TResizeForm.ReadScale(): TVec3;
begin
     result.x := strtofloatdef(XEdit.Text, 0);
     result.y := strtofloatdef(YEdit.Text, 0);
     result.z := strtofloatdef(ZEdit.Text, 0);
     if min(min(result.x, result.y), result.z) <= 0.0 then
        result.x := 0; //error
end;

procedure TResizeForm.EditChange(Sender: TObject);
var
  Scale, outMM : TVec3;
  outDim: TVec3i;
  bpp: integer;
  inBytes, outBytes: int64;

begin
     Scale := ReadScale;
     if Scale.x <= 0.0 then begin
       OutLabel.Caption:= 'Output: Invalid Scaling';
       exit;
     end;
     outDim.x := round(gDim.x * Scale.x);
     Scale.x := outDim.x / gDim.x; //e.g. rounding error
     outMM.x := gMM.x / Scale.x;
     outDim.y := round(gDim.y * Scale.y);
     Scale.y := outDim.y / gDim.y; //e.g. rounding error
     outMM.y := gMM.y / Scale.y;
     outDim.z := round(gDim.z * Scale.z);
     Scale.z := outDim.z / gDim.z; //e.g. rounding error
     outMM.z := gMM.z / Scale.z;
     OutLabel.Caption:= format('Output: %dx%dx%d voxels %.4gx%.4gx%.4g mm', [outDim.x, outDim.y, outDim.z, outMM.x, outMM.y, outMM.z]);
     inBytes := gDim.X * gDim.y * gDim.z * (gBPP div 8);
     if inBytes <= 0 then exit;
     if not DataTypeDrop.enabled then //DT_RGB
        bpp := 24
     else if DataTypeDrop.ItemIndex = 0 then
        bpp := 8
     else if DataTypeDrop.ItemIndex = 1 then
          bpp := 16
     else
         bpp := 32;
     outBytes := outDim.x * outDim.y * outDim.z * (bpp div 8);
     ChangeLabel.Caption := format('Change in uncompressed size: x%.4g', [outBytes/inBytes]);
end;

procedure TResizeForm.FormShow(Sender: TObject);
begin
     EditChange(nil);
end;

procedure TResizeForm.IsotropicBtnClick(Sender: TObject);
var
  mmMx, mmMn: single;
begin
      mmMx := max(max(gMM.x,gMM.y),gMM.z);
      mmMn := min(min(gMM.x,gMM.y),gMM.z);
      if (mmMn = 0) or (mmMn = mmMx) then exit;
      XEdit.Text :=  floattostr(gMM.x/ mmMn);
      yEdit.Text :=  floattostr(gMM.y/ mmMn);
      zEdit.Text :=  floattostr(gMM.z/ mmMn);
end;

procedure TResizeForm.IsotropicShrinkBtnClick(Sender: TObject);
var
  mmMx, mmMn: single;
begin
      mmMx := max(max(gMM.x,gMM.y),gMM.z);
      mmMn := min(min(gMM.x,gMM.y),gMM.z);
      if (mmMn = 0) or (mmMn = mmMx) then exit;
      XEdit.Text :=  floattostr(gMM.x/ mmMx);
      yEdit.Text :=  floattostr(gMM.y/ mmMx);
      zEdit.Text :=  floattostr(gMM.z/ mmMx);
end;

//function TResizeForm.GetScale(const Dim: TVec3i; const mm: TVec3; filename: string; var datatype: integer; out Filter: integer): TVec3;
function TResizeForm.GetScale(hdr: TNIFTIhdr; isLabel: boolean; filename: string; out datatype: integer;  out Filter: integer; out isAllVolumes: boolean): TVec3;
begin
     gMM.x := hdr.pixdim[1];
     gMM.y := hdr.pixdim[2];
     gMM.z := hdr.pixdim[3];
     gDim.x := hdr.dim[1];
     gDim.y := hdr.dim[2];
     gDim.z := hdr.dim[3];
     gBPP := hdr.bitpix;
     //gMM := mm;
     //gDim := Dim;
     DataTypeDrop.Enabled := true;
     AllVolumesCheck.Enabled := hdr.dim[4] > 1;
     if hdr.datatype = kDT_RGB then begin
        DataTypeDrop.ItemIndex := 0;
        DataTypeDrop.Enabled := false;
     end else if hdr.datatype = kDT_UNSIGNED_CHAR then
        DataTypeDrop.ItemIndex := 0
     else if hdr.datatype = kDT_SIGNED_SHORT then
          DataTypeDrop.ItemIndex := 1
     else if hdr.datatype = kDT_FLOAT then
          DataTypeDrop.ItemIndex := 2;
     if isLabel then
        FilterDrop.ItemIndex := 0 //Nearest
     else
         FilterDrop.ItemIndex := 7; //Automatic Mitchell
     IsotropicBtn.Enabled := (gMM.x <> gMM.y) or (gMM.x <> gMM.z);
     IsotropicShrinkBtn.Enabled := IsotropicBtn.Enabled;
     Caption := 'Resize '+filename;
     InLabel.Caption:= format('Input: %dx%dx%d voxels %.4gx%.4gx%.4g mm', [gDim.x, gDim.y, gDim.z, gMM.x, gMM.y, gMM.z]);
     Self.showmodal;
     result := ReadScale();
     Filter :=  FilterDrop.ItemIndex;
     if hdr.datatype = kDT_RGB then
        datatype := kDT_RGB
     else if DataTypeDrop.ItemIndex = 0 then
          datatype := kDT_UNSIGNED_CHAR
     else if DataTypeDrop.ItemIndex = 1 then
          datatype := kDT_SIGNED_SHORT
     else
         datatype := kDT_FLOAT;
     if Self.ModalResult <> mrOK then
        result.x := 0; //invalid
     isAllVolumes := AllVolumesCheck.checked;
end;

end.

