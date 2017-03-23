unit ProgressDialog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, JvGIF,
  JvExControls, JvAnimatedImage, JvGIFCtrl;

type
  TFProgressDialog = class(TForm)
    pnl1: TPanel;
    lbl1: TLabel;
    lblMSG: TLabel;
    JvGIFAnimator1: TJvGIFAnimator;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FProgressDialog: TFProgressDialog;

implementation

{$R *.dfm}

end.
