object Form1: TForm1
  Left = 721
  Top = 169
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Simple MapMerger'
  ClientHeight = 441
  ClientWidth = 466
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lbl1: TLabel
    Left = 176
    Top = 0
    Width = 3
    Height = 13
  end
  object lbl2: TLabel
    Left = 176
    Top = 13
    Width = 3
    Height = 13
  end
  object lbl3: TLabel
    Left = 176
    Top = 26
    Width = 3
    Height = 13
  end
  object g1: TGauge
    Left = 1
    Top = 48
    Width = 166
    Height = 14
    BackColor = clBtnFace
    Color = clBtnFace
    ParentColor = False
    Progress = 0
  end
  object redt1: TRichEdit
    Left = 0
    Top = 68
    Width = 466
    Height = 373
    Align = alBottom
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Lines.Strings = (
      'redt1')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object btn1: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 33
    Hint = '>> Click to change <<'
    Caption = 'Work Dir (Startup)'
    TabOrder = 1
    WordWrap = True
    OnClick = btn1Click
  end
  object btn2: TButton
    Left = 88
    Top = 8
    Width = 75
    Height = 33
    Caption = 'Start merge'
    TabOrder = 2
    OnClick = btn2Click
  end
  object btn3: TButton
    Left = 384
    Top = 40
    Width = 75
    Height = 17
    Caption = 'Clear Log'
    TabOrder = 3
    OnClick = btn3Click
  end
  object chk1: TCheckBox
    Left = 368
    Top = 0
    Width = 97
    Height = 17
    Hint = '[v]: MD5'#13#10'[  ]: CRC32|Checked: MD5'#13#10'UnChecked: CRC32'
    Caption = 'MD5 / CRC32'
    Checked = True
    ParentShowHint = False
    ShowHint = True
    State = cbChecked
    TabOrder = 4
  end
  object grp1: TGroupBox
    Left = 296
    Top = 0
    Width = 65
    Height = 49
    Caption = 'Log level '
    TabOrder = 5
    object lbl4: TLabel
      Left = 6
      Top = 32
      Width = 45
      Height = 10
      Caption = '   1       2      3'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'Small Fonts'
      Font.Style = []
      ParentFont = False
    end
    object trckbr1: TTrackBar
      Left = 8
      Top = 16
      Width = 49
      Height = 18
      Hint = 'Log level'
      Max = 3
      Min = 1
      ParentShowHint = False
      PageSize = 1
      Position = 1
      ShowHint = True
      TabOrder = 0
      ThumbLength = 10
    end
  end
  object chk2: TCheckBox
    Left = 368
    Top = 16
    Width = 97
    Height = 17
    Hint = 
      #1054#1075#1088#1072#1085#1080#1095#1077#1085#1080#1077' '#1087#1086#1080#1089#1082#1072' '#1089#1086#1074#1087#1072#1076#1077#1085#1080#1081' 3-'#1084#1103' '#1092#1072#1081#1083#1072#1084#1080'.'#13#10#1042' '#1089#1074#1103#1079#1080' '#1089' '#1085#1077' '#1087#1086#1083#1085#1086#1081 +
      ' '#1087#1088#1086#1074#1077#1088#1082#1086#1081', '#1074#1086#1079#1084#1086#1078#1085#1086' '#1074#1086#1079#1085#1080#1082#1085#1086#1074#1077#1085#1080#1077' '#1086#1096#1080#1073#1086#1082' !!!|'#1054#1075#1088#1072#1085#1080#1095#1077#1085#1080#1077' '#1087#1086#1080#1089#1082#1072 +
      ' '#1089#1086#1074#1087#1072#1076#1077#1085#1080#1081' 3-'#1084#1103' '#1092#1072#1081#1083#1072#1084#1080'.'#13#10#1042' '#1089#1074#1103#1079#1080' '#1089' '#1085#1077' '#1087#1086#1083#1085#1086#1081' '#1087#1088#1086#1074#1077#1088#1082#1086#1081', '#1074#1086#1079#1084#1086#1078 +
      #1085#1086' '#1074#1086#1079#1085#1080#1082#1085#1086#1074#1077#1085#1080#1077' '#1086#1096#1080#1073#1086#1082' !!!'
    Caption = 'Hardcap (3)'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 6
  end
  object dlgOpen1: TOpenDialog
    FileName = 'Ignored ...'
    Filter = 'HTML Map (map.html)|map.html|All Files|*.*'
    Options = [ofReadOnly, ofPathMustExist, ofEnableSizing, ofForceShowHidden]
    Title = 'Select "map.html" file'
    Left = 392
    Top = 112
  end
end
