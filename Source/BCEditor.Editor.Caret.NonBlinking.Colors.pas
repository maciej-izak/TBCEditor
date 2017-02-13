unit BCEditor.Editor.Caret.NonBlinking.Colors;

interface

uses
  System.Classes, Vcl.Graphics;

type
  TBCEditorCaretNonBlinkingColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FForeground: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write FBackground default clBlack;
    property Foreground: TColor read FForeground write FForeground default clWhite;
  end;

implementation

constructor TBCEditorCaretNonBlinkingColors.Create;
begin
  inherited;

  FBackground := clBlack;
  FForeground := clWhite;
end;

procedure TBCEditorCaretNonBlinkingColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TBCEditorCaretNonBlinkingColors) then
  with ASource as TBCEditorCaretNonBlinkingColors do
  begin
    Self.FBackground := FBackground;
    Self.FForeground := FForeground;
  end
  else
    inherited Assign(ASource);
end;

end.
