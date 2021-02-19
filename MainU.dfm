object FormMain: TFormMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'FormMain'
  ClientHeight = 249
  ClientWidth = 568
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object btActivateLLKeyHook: TButton
    Left = 160
    Top = 8
    Width = 146
    Height = 25
    Hint = 'Traps all but Numpad Keys System Wide'
    Caption = 'Activate LLKeyboard'
    TabOrder = 0
    OnClick = btActivateLLKeyHookClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 39
    Width = 548
    Height = 34
    Lines.Strings = (
      'Activate at least one Keyboard hook and type here')
    TabOrder = 1
  end
  object ListBox1: TListBox
    Left = 8
    Top = 110
    Width = 552
    Height = 88
    Columns = 4
    ItemHeight = 13
    Items.Strings = (
      'Active the GetMsg Hook then '
      'use the System Menu to test')
    TabOrder = 2
  end
  object btActivateGetMsgHook: TButton
    Left = 8
    Top = 79
    Width = 146
    Height = 25
    Hint = 'Shows System Menu clicked in Listbox'
    Caption = 'Activate GetMsg'
    TabOrder = 3
    OnClick = btActivateGetMsgHookClick
  end
  object btActivateKeyboard: TButton
    Left = 8
    Top = 8
    Width = 146
    Height = 25
    Hint = 'Traps all but Numpad Keys for this thread'
    Caption = 'Activate Keyboard'
    TabOrder = 4
    OnClick = btActivateKeyboardClick
  end
  object btActivateMouse: TButton
    Left = 8
    Top = 204
    Width = 146
    Height = 25
    Hint = 'Traps Click Events on "You Can'#39't Click Me"'
    Caption = 'Activate Mouse Hook'
    TabOrder = 5
    OnClick = btActivateMouseClick
  end
  object btYouCantClickMe: TButton
    Left = 168
    Top = 204
    Width = 148
    Height = 25
    Caption = 'You Can'#39't Click Me!'
    Enabled = False
    TabOrder = 6
  end
  object ckInvert: TCheckBox
    Left = 321
    Top = 16
    Width = 97
    Height = 17
    Hint = 'Invert Keys trapped'
    Caption = 'Invert'
    TabOrder = 7
  end
end
