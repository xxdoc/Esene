VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "APIClass"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'********************************************************************************
'
'Name.......... APIClass
'File.......... APIClass.cls
'Version....... 1.0.0
'Dependencies.. kernel32.DLL
'Author........ Supermanking
'Date.......... Apr, 17nd 2008
'UpdateURL..... http://bbs.rljy.com/?m=vbAPIClass
'
'Copyright (c) 2008 by www.rljy.com
'Liuzhou city, China
'
'********************************************************************************
Option Explicit
'==============================================================================
'�������Ͷ���
'==============================================================================
Private Type VariableBuffer
    VariableParameter()       As Byte
End Type
'==============================================================================
'API ��������
'==============================================================================
Private Declare Function LoadLibrary Lib "kernel32" Alias "LoadLibraryA" (ByVal lpLibFileName As String) As Long
Private Declare Function GetProcAddress Lib "kernel32" (ByVal hModule As Long, ByVal lpProcName As String) As Long
Private Declare Function CallWindowProc Lib "user32" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hwnd As Long, ByVal Msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Declare Function FreeLibrary Lib "kernel32" (ByVal hLibModule As Long) As Long
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (lpDest As Any, lpSource As Any, ByVal cBytes As Long)
'==============================================================================
'��Ա����
'==============================================================================
'���е�ȫ�ֱ���
Private m_opIndex As Long
Private m_OpCode()       As Byte
'********************************************************************************
'**  ��    �� ��    ����(Supermanking)
'**  �� �� �� ��    ExecuteAPI
'**  ��    �� ��    LIBPath(String)        -  ˢ�µ�Ŀ�괰�ھ������Ϊ0
'**            ��    APIScript(String)      -  ����ͼ��Ŀ���
'**  ��    �� ��    (Long)                  -  �������ʾʧ�ܣ������ʾ�ɹ�
'**  �������� ��    ��ִ̬��������API����
'**  �������� ��    2008-04-17
'**  �� �� �� ��
'**  �޸����� ��
'**  ��    �� ��    Version 1.0.0
'********************************************************************************
Public Function ExecuteAPI(LibPath As String, APIScript As String) As Long
    Dim hProcAddress As Long, hModule As Long, X As Long, Y As Long
    Dim RetLong As Long, FunctionName As String, FunctionParameter As String
    Dim LongCount As Long, StringInfo As String, StrByteArray()       As VariableBuffer
    Dim StringSize As Long, ByteArray()       As Byte, IsHaveParameter As Boolean
    Dim ParameterArray()       As String, OutputArray()       As Long
    StringSize = 0
    ReDim StrByteArray(StringSize)
  'ʶ��������
    RetLong = InStr(1, APIScript, " ", vbTextCompare)
    If RetLong = 0 Then
      'û�в����ĺ���
            FunctionName = APIScript
            IsHaveParameter = False
    Else
      '�������ĺ���
            FunctionName = Left(APIScript, RetLong - 1)
            IsHaveParameter = True
             
      'ʶ��������
            FunctionParameter = Right(APIScript, Len(APIScript) - RetLong)
     
      '������������
            ParameterArray = Split(FunctionParameter, ",")
     
      '��ʼ�������ڴ��С
            ReDim OutputArray(UBound(ParameterArray))
     
      '��ʽ����������
            For X = 0 To UBound(ParameterArray)
                If IsNumeric(Trim(ParameterArray(X))) = True Then
                        LongCount = CLng(Trim(ParameterArray(X)))
                        OutputArray(X) = LongCount
                Else
                        StringInfo = Mid(Trim(ParameterArray(X)), 2, Len(ParameterArray(X)) - 3)
                        If Len(StringInfo) = 0 Then
                            OutputArray(X) = CLng(VarPtr(Null))
                        Else
                            ReDim Preserve StrByteArray(StringSize)
                            ByteArray = StrConv(StringInfo, vbFromUnicode)
                            ReDim Preserve StrByteArray(StringSize).VariableParameter(UBound(ByteArray) + 1)
                            CopyMemory StrByteArray(StringSize).VariableParameter(0), ByteArray(0), UBound(ByteArray) + 1
                            OutputArray(X) = CLng(VarPtr(StrByteArray(StringSize).VariableParameter(0)))
                            StringSize = StringSize + 1
                        End If
                End If
            Next X
            ReDim m_OpCode(400 + 6 * UBound(OutputArray))           '��������дm_OpCode
    End If
     
  '��ȡAPI��
    hModule = LoadLibrary(ByVal LibPath)
    If hModule = 0 Then
            ExecuteAPI = 0       'Library ��ȡʧ��
            Exit Function
    End If

  'ȡ�ú�����ַ
    hProcAddress = GetProcAddress(hModule, ByVal FunctionName)
    If hProcAddress = 0 Then
            ExecuteAPI = 0       '������ȡʧ��
            FreeLibrary hModule
            Exit Function
    End If
     
    If IsHaveParameter = True Then
      '������������ڴ�ִ��
            ExecuteAPI = CallWindowProc(GetCodeStart(hProcAddress, OutputArray), 0, 1, 2, 3)
    Else
      '��������������ڴ�ִ��
            ExecuteAPI = CallWindowProc(hProcAddress, 0, 1, 2, 3)
    End If
     
  '�ͷſ�ռ�
    FreeLibrary hModule
End Function

Private Function GetCodeStart(ByVal lngProc As Long, arrParams() As Long) As Long
        Dim lngIndex As Long, lngCodeStart As Long
        lngCodeStart = (VarPtr(m_OpCode(0)) Or &HF) + 1
        m_opIndex = lngCodeStart - VarPtr(m_OpCode(0))
        For lngIndex = 0 To m_opIndex - 1
                m_OpCode(lngIndex) = &HCC
        Next lngIndex
        For lngIndex = UBound(arrParams) To 0 Step -1
            AddByteToCode &H68
            AddLongToCode arrParams(lngIndex)
        Next lngIndex
        AddByteToCode &HE8
        AddLongToCode lngProc - VarPtr(m_OpCode(m_opIndex)) - 4
        AddByteToCode &HC2
        AddByteToCode &H10
        AddByteToCode &H0
        GetCodeStart = lngCodeStart
End Function

Private Sub AddLongToCode(lData As Long)
        CopyMemory m_OpCode(m_opIndex), lData, 4
        m_opIndex = m_opIndex + 4
End Sub

Private Sub AddIntToCode(iData As Integer)
        CopyMemory m_OpCode(m_opIndex), iData, 2
        m_opIndex = m_opIndex + 2
End Sub

Private Sub AddByteToCode(bData As Byte)
        m_OpCode(m_opIndex) = bData
        m_opIndex = m_opIndex + 1
End Sub