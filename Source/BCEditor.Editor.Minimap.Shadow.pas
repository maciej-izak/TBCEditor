unit BCEditor.Editor.Minimap.Shadow;

interface

uses
  System.Classes, Vcl.Graphics;

type
  TBCEditorMinimapShadow = class(TPersistent)
  strict private
    FAlphaBlending: Byte;
    FColor: TColor;
    FOnChange: TNotifyEvent;
    FVisible: Boolean;
    FWidth: Integer;
    procedure DoChange;
    procedure SetAlphaBlending(const AValue: Byte);
    procedure SetColor(const AValue: TColor);
    procedure SetVisible(const AValue: Boolean);
    procedure SetWidth(const AValue: Integer);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property AlphaBlending: Byte read FAlphaBlending write SetAlphaBlending default 96;
    property Color: TColor read FColor write SetColor default clBlack;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Visible: Boolean read FVisible write SetVisible default False;
    property Width: Integer read FWidth write SetWidth default 8;
  end;

implementation

constructor TBCEditorMinimapShadow.Create;
begin
  inherited;

  FAlphaBlending := 96;
  FColor := clBlack;
  FVisible := False;
  FWidth := 8;
end;

procedure TBCEditorMinimapShadow.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TBCEditorMinimapShadow) then
  with ASource as TBCEditorMinimapShadow do
  begin
    Self.FAlphaBlending := FAlphaBlending;
    Self.FColor := FColor;
    Self.FVisible := FVisible;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TBCEditorMinimapShadow.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TBCEditorMinimapShadow.SetAlphaBlending(const AValue: Byte);
begin
  if FAlphaBlending <> AValue then
  begin
    FAlphaBlending := AValue;
    DoChange;
  end;
end;

procedure TBCEditorMinimapShadow.SetColor(const AValue: TColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    DoChange;
  end;
end;

procedure TBCEditorMinimapShadow.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange;
  end;
end;

procedure TBCEditorMinimapShadow.SetWidth(const AValue: Integer);
begin
  if FWidth <> AValue then
  begin
    FWidth := AValue;
    DoChange;
  end;
end;

end.
