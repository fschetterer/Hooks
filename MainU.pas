unit MainU;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Threading, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  WinApi.Hooks;

type
  TFormMain = class(TForm)
    btActivateLLKeyHook: TButton;
    Memo1: TMemo;
    ListBox1: TListBox;
    btActivateGetMsgHook: TButton;
    btActivateKeyboard: TButton;
    btActivateMouse: TButton;
    btYouCantClickMe: TButton;
    ckInvert: TCheckBox;
    procedure btActivateGetMsgHookClick(Sender: TObject);
    procedure btActivateKeyboardClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btActivateLLKeyHookClick(Sender: TObject);
    procedure btActivateMouseClick(Sender: TObject);
  private
    FLLKeyHook : THook;
    FKeyHook   : THook;
    FGetMSgHook: THook;
    FMouseHook : THook;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

const
  Captions: array [Boolean] of string = ('Deactivate', 'Activate');
  VK_NUMBERS = [vk0..vk9, vkNumpad0..vkNumpad9];


procedure TFormMain.btActivateGetMsgHookClick(Sender: TObject);
begin
  FGetMSgHook.Active := not FGetMSgHook.Active;
  TButton(Sender).Caption := Captions[not FGetMSgHook.Active];
end;

procedure TFormMain.btActivateKeyboardClick(Sender: TObject);
begin
  FKeyHook.Active := not FKeyHook.Active;
  TButton(Sender).Caption := Captions[not FKeyHook.Active];
end;

procedure TFormMain.btActivateLLKeyHookClick(Sender: TObject);
begin
  FLLKeyHook.Active := not FLLKeyHook.Active;
  TButton(Sender).Caption := Captions[not FLLKeyHook.Active];
end;

procedure TFormMain.btActivateMouseClick(Sender: TObject);
begin
  FMouseHook.Active := not FMouseHook.Active;
  TButton(Sender).Caption := Captions[not FMouseHook.Active];
  btYouCantClickMe.Enabled := FMouseHook.Active;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FLLKeyHook := THookInstance<TLowLevelKeyboardHook>.CreateHook(Self);
  FLLKeyHook.OnPreExecute := procedure(AHook: THook; var AHookMsg: THookMessage)
    var LHook: TLowLevelKeyboardHook absolute AHook; LTrap : Boolean;
    begin
      if not LHook.HookStruct.IsKeyDown then exit;
      LTrap := not (LHook.HookStruct.vkCode in VK_NUMBERS);
      if ckInvert.Checked then LTrap := not LTrap;
      if LTrap then begin
        Caption := 'Got ya! Key [' + LHook.KeyExtName + '] blocked.';
        AHookMsg.Handled := True;
      end else Caption := 'Char: '+ LHook.KeyChar;
    end;

  FKeyHook := THookInstance<TKeyboardHook>.CreateHook(Self);
  FKeyHook.OnPreExecute := procedure(AHook: THook; var AHookMsg: THookMessage)
    var LHook: TKeyboardHook absolute AHook; LTrap : Boolean;
    begin
      if not LHook.KeyStates.IsKeyDown then Exit;
      LTrap := not (AHookMsg.WParam in VK_NUMBERS);
      if ckInvert.Checked then LTrap := not LTrap;
      if LTrap then begin
        Caption := 'Got ya! Key [' + LHook.GetKeyExtName(AHookMsg) + '] blocked.';
        AHookMsg.Handled := True;
      end else Caption := 'Char: '+ LHook.GetKeyChar(AHookMsg);
    end;

  FGetMSgHook := THookInstance<TGetMessageHook>.CreateHook(Self);
  FGetMSgHook.OnPreExecute := procedure(AHook: THook; var AHookMsg: THookMessage)
    procedure AddToList(s: string; lParam : LPARAM);
    begin
       with ListBox1 do ItemIndex := Items.Add(Format('%s: %d', [s, LParam]));
    end;

    var LHook: TGetMessageHook absolute AHook;
    begin
      if (LHook.Msg.Message = WM_SYSCOMMAND) then begin
        with LHook.Msg^ do case (wParam and $FFF0) of
          SC_CLOSE: AddToList('SC_CLOSE', lParam);
          SC_CONTEXTHELP: AddToList('SC_CONTEXTHELP', lParam);
          SC_DEFAULT: AddToList('SC_DEFAULT', lParam);
          SC_HOTKEY: AddToList('SC_HOTKEY', lParam);
          SC_HSCROLL: AddToList('SC_HSCROLL', lParam);
          SC_KEYMENU: AddToList('SC_KEYMENU', lParam);
          SC_MAXIMIZE: AddToList('SC_MAXIMIZE', lParam);
          SC_MINIMIZE: AddToList('SC_MINIMIZE', lParam);
          SC_MONITORPOWER: AddToList('SC_MONITORPOWER', lParam);
          SC_MOUSEMENU: AddToList('SC_MOUSEMENU', lParam);
          SC_MOVE: AddToList('SC_MOVE', lParam);
          SC_NEXTWINDOW: AddToList('SC_NEXTWINDOW', lParam);
          SC_PREVWINDOW: AddToList('SC_PREVWINDOW', lParam);
          SC_RESTORE: AddToList('SC_RESTORE', lParam);
          SC_SCREENSAVE: AddToList('SC_SCREENSAVE', lParam);
          SC_SIZE: AddToList('SC_SIZE', lParam);
          SC_TASKLIST: AddToList('SC_TASKLIST', lParam);
          SC_VSCROLL: AddToList('SC_VSCROLL', lParam);
        end;
      AHookMsg.Handled := True;
      end;
    end;

    FMouseHook := THookInstance<TMouseHook>.CreateHook(Self);
    FMouseHook.OnPreExecute := procedure(AHook: THook; var AHookMsg: THookMessage)
      var LHook : TMouseHook absolute AHook;
      begin
        if not ( (AHookMsg.WParam = WM_LBUTTONDOWN)
              or (AHookMsg.WParam = WM_LBUTTONDBLCLK))
        or (btYouCantClickMe.Handle <> LHook.HookStruct.hwnd)
        or not btYouCantClickMe.Enabled then Exit;

        AHookMsg.Handled := btYouCantClickMe.BoundsRect.Contains(ScreenToClient(LHook.HookStruct.pt));
      end;
end;

end.
