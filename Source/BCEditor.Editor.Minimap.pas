unit BCEditor.Editor.Minimap;

interface

uses
  System.Classes, System.UITypes, Vcl.Graphics, BCEditor.Types, BCEditor.Editor.Minimap.Indicator,
  BCEditor.Editor.Minimap.Colors, BCEditor.Editor.Minimap.Shadow;

type
  TBCEditorMinimap = class(TPersistent)
  strict private
    FAlign: TBCEditorMinimapAlign;
    FCharHeight: Integer;
    FClicked: Boolean;
    FColors: TBCEditorMinimapColors;
    FCursor: TCursor;
    FDragging: Boolean;
    FFont: TFont;
    FIndicator: TBCEditorMinimapIndicator;
    FOnChange: TNotifyEvent;
    FOptions: TBCEditorMinimapOptions;
    FShadow: TBCEditorMinimapShadow;
    FTopLine: Integer;
    FVisible: Boolean;
    FVisibleLines: Integer;
    FWidth: Integer;
    procedure DoChange;
    procedure SetAlign(const AValue: TBCEditorMinimapAlign);
    procedure SetColors(const AValue: TBCEditorMinimapColors);
    procedure SetFont(AValue: TFont);
    procedure SetOnChange(AValue: TNotifyEvent);
    procedure SetVisible(AValue: Boolean);
    procedure SetWidth(AValue: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    function GetWidth: Integer;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TBCEditorMinimapOption; const AEnabled: Boolean);
    property CharHeight: Integer read FCharHeight write FCharHeight;
    property Clicked: Boolean read FClicked write FClicked;
    property Dragging: Boolean read FDragging write FDragging;
    property TopLine: Integer read FTopLine write FTopLine default 1;
    property VisibleLines: Integer read FVisibleLines write FVisibleLines;
  published
    property Align: TBCEditorMinimapAlign read FAlign write SetAlign default maRight;
    property Colors: TBCEditorMinimapColors read FColors write SetColors;
    property Cursor: TCursor read FCursor write FCursor default crArrow;
    property Font: TFont read FFont write SetFont;
    property Indicator: TBCEditorMinimapIndicator read FIndicator write FIndicator;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
    property Options: TBCEditorMinimapOptions read FOptions write FOptions default [];
    property Shadow: TBCEditorMinimapShadow read FShadow write FShadow;
    property Visible: Boolean read FVisible write SetVisible default False;
    property Width: Integer read FWidth write SetWidth default 140;
  end;

implementation

uses
  System.Math;

constructor TBCEditorMinimap.Create;
begin
  inherited;

  FAlign := maRight;

  FFont := TFont.Create;
  FFont.Name := 'Courier New';
  FFont.Size := 1;
  FFont.Style := [];

  FVisible := False;
  FWidth := 140;
  FDragging := False;
  FOptions := [];
  FCursor := crArrow;

  FClicked := False;

  FTopLine := 1;

  FIndicator := TBCEditorMinimapIndicator.Create;
  FColors := TBCEditorMinimapColors.Create;
  FShadow := TBCEditorMinimapShadow.Create;
end;

destructor TBCEditorMinimap.Destroy;
begin
  FFont.Free;
  FIndicator.Free;
  FColors.Free;
  FShadow.Free;

  inherited Destroy;
end;

procedure TBCEditorMinimap.Assign(ASource: TPersistent);
begin
  if ASource is TBCEditorMinimap then
  with ASource as TBCEditorMinimap do
  begin
    Self.FAlign := FAlign;
    Self.FColors.Assign(FColors);
    Self.FShadow.Assign(FShadow);
    Self.FFont.Assign(FFont);
    Self.FOptions := FOptions;
    Self.FVisible := FVisible;
    Self.FWidth := FWidth;
    Self.FCursor := FCursor;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TBCEditorMinimap.SetOnChange(AValue: TNotifyEvent);
begin
  FOnChange := AValue;
  FFont.OnChange := AValue;
  FColors.OnChange := AValue;
  FIndicator.OnChange := AValue;
  FShadow.OnChange := AValue;
end;

procedure TBCEditorMinimap.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TBCEditorMinimap.SetOption(const AOption: TBCEditorMinimapOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

procedure TBCEditorMinimap.SetAlign(const AValue: TBCEditorMinimapAlign);
begin
  if FAlign <> AValue then
  begin
    FAlign := AValue;
    DoChange;
  end;
end;

procedure TBCEditorMinimap.SetColors(const AValue: TBCEditorMinimapColors);
begin
  FColors.Assign(AValue);
end;

procedure TBCEditorMinimap.SetFont(AValue: TFont);
begin
  FFont.Assign(AValue);
end;

procedure TBCEditorMinimap.SetWidth(AValue: Integer);
begin
  AValue := Max(0, AValue);
  if FWidth <> AValue then
  begin
    FWidth := AValue;
    DoChange;
  end;
end;

function TBCEditorMinimap.GetWidth: Integer;
begin
  if FVisible then
    Result := FWidth
  else
    Result := 0;
end;

procedure TBCEditorMinimap.SetVisible(AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    DoChange;
  end;
end;

end.
