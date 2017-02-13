unit BCEditor.Editor.Search.Highlighter.Colors;

interface

uses
  System.Classes, Vcl.Graphics, BCEditor.Consts, BCEditor.Types;

type
  TBCEditorSearchColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FBorder: TColor;
    FForeground: TColor;
    FOnChange: TBCEditorSearchChangeEvent;
    procedure SetBackground(const AValue: TColor);
    procedure SetBorder(const AValue: TColor);
    procedure SetForeground(const AValue: TColor);
    procedure DoChange;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write SetBackground default clSearchHighlighter;
    property Border: TColor read FBorder write SetBorder default clNone;
    property Foreground: TColor read FForeground write SetForeground default clWindowText;
    property OnChange: TBCEditorSearchChangeEvent read FOnChange write FOnChange;
  end;

implementation

constructor TBCEditorSearchColors.Create;
begin
  inherited;

  FBackground := clSearchHighlighter;
  FBorder := clNone;
  FForeground := clWindowText;
end;

procedure TBCEditorSearchColors.Assign(ASource: TPersistent);
begin
  if ASource is TBCEditorSearchColors then
  with ASource as TBCEditorSearchColors do
  begin
    Self.FBackground := FBackground;
    Self.FBorder := FBorder;
    Self.FForeground := FForeground;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TBCEditorSearchColors.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(scRefresh);
end;

procedure TBCEditorSearchColors.SetBackground(const AValue: TColor);
begin
  if FBackground <> AValue then
  begin
    FBackground := AValue;
    DoChange;
  end;
end;

procedure TBCEditorSearchColors.SetBorder(const AValue: TColor);
begin
  if FBorder <> AValue then
  begin
    FBorder := AValue;
    DoChange;
  end;
end;

procedure TBCEditorSearchColors.SetForeground(const AValue: TColor);
begin
  if FForeground <> AValue then
  begin
    FForeground := AValue;
    DoChange;
  end;
end;

end.
