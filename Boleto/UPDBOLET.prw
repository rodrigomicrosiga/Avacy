#INCLUDE "PROTHEUS.CH"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

/*
�����������������������������������������������������������������������������
��� Programa � UPDFST   �                                                 ���
�������������������������������������������������������������������������͹��
��� Descricao� Funcao de update dos dicion�rios para compatibiliza��o     ���
�����������������������������������������������������������������������������
*/
user Function UPDBOLET( cEmpAmb, cFilAmb )

Local   aSay      := {}
Local   aButton   := {}
Local   aMarcadas := {}
Local   cTitulo   := "ATUALIZA��O DE DICION�RIOS E TABELAS"
Local   cDesc1    := "Esta rotina tem como fun��o fazer  a atualiza��o  dos dicion�rios do Sistema ( SX?/SIX )"
Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja n�o podem haver outros"
Local   cDesc3    := "usu�rios  ou  jobs utilizando  o sistema.  � extremamente recomendav�l  que  se  fa�a um"
Local   cDesc4    := "BACKUP  dos DICION�RIOS  e da  BASE DE DADOS antes desta atualiza��o, para que caso "
Local   cDesc5    := "ocorra eventuais falhas, esse backup seja ser restaurado."
Local   cDesc6    := ""
Local   cDesc7    := ""
Local   lOk       := .F.
Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

Private oMainWnd  := NIL
Private oProcess  := NIL

#IFDEF TOP
    TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
#ENDIF

__cInterNet := NIL
__lPYME     := .F.

Set Dele On

// Mensagens de Tela Inicial
aAdd( aSay, cDesc1 )
aAdd( aSay, cDesc2 )
aAdd( aSay, cDesc3 )
aAdd( aSay, cDesc4 )
aAdd( aSay, cDesc5 )
//aAdd( aSay, cDesc6 )
//aAdd( aSay, cDesc7 )

// Botoes Tela Inicial
aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

If lAuto
	lOk := .T.
Else
	FormBatch(  cTitulo,  aSay,  aButton )
EndIf

If lOk
	If lAuto
		aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
	Else
		aMarcadas := EscEmpresa()
	EndIf

	If !Empty( aMarcadas )
		If lAuto .OR. MsgNoYes( "Confirma a atualiza��o dos dicion�rios ?", cTitulo )
			oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
			oProcess:Activate()

		If lAuto
			If lOk
				MsgStop( "Atualiza��o Realizada.", "UPDFST" )
				dbCloseAll()
			Else
				MsgStop( "Atualiza��o n�o Realizada.", "UPDFST" )
				dbCloseAll()
			EndIf
		Else
			If lOk
				Final( "Atualiza��o Conclu�da." )
			Else
				Final( "Atualiza��o n�o Realizada." )
			EndIf
		EndIf

		Else
			MsgStop( "Atualiza��o n�o Realizada.", "UPDFST" )

		EndIf

	Else
		MsgStop( "Atualiza��o n�o Realizada.", "UPDFST" )

	EndIf

EndIf

Return NIL


/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
��� Programa � FSTProc  � Autor �       Protheus     � Data �  12/08/2017 ���
�������������������������������������������������������������������������͹��
��� Descricao� Funcao de processamento da grava��o dos arquivos           ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
��� Uso      � FSTProc    - Gerado por EXPORDIC / Upd. V.4.10.6 EFS       ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function FSTProc( lEnd, aMarcadas )
Local   aInfo     := {}
Local   aRecnoSM0 := {}
Local   cAux      := ""
Local   cFile     := ""
Local   cFileLog  := ""
Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
Local   cTCBuild  := "TCGetBuild"
Local   cTexto    := ""
Local   cTopBuild := ""
Local   lOpen     := .F.
Local   lRet      := .T.
Local   nI        := 0
Local   nPos      := 0
Local   nRecno    := 0
Local   nX        := 0
Local   oDlg      := NIL
Local   oFont     := NIL
Local   oMemo     := NIL

Private aArqUpd   := {}

If ( lOpen := MyOpenSm0(.T.) )

	dbSelectArea( "SM0" )
	dbGoTop()

	While !SM0->( EOF() )
		// So adiciona no aRecnoSM0 se a empresa for diferente
		If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
		   .AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
			aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
		EndIf
		SM0->( dbSkip() )
	End

	SM0->( dbCloseArea() )

	If lOpen

		For nI := 1 To Len( aRecnoSM0 )

			If !( lOpen := MyOpenSm0(.F.) )
				MsgStop( "Atualiza��o da empresa " + aRecnoSM0[nI][2] + " n�o efetuada." )
				Exit
			EndIf

			SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

			RpcSetType( 3 )
			RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

			lMsFinalAuto := .F.
			lMsHelpAuto  := .F.

			cTexto += Replicate( "-", 128 ) + CRLF
			cTexto += "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF + CRLF

			oProcess:SetRegua1( 8 )

			//����������������������������������Ŀ
			//�Atualiza o dicion�rio SX3         �
			//������������������������������������
			FSAtuSX3( @cTexto )

			oProcess:IncRegua1( "Dicion�rio de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			oProcess:IncRegua2( "Atualizando campos/�ndices" )

			// Alteracao fisica dos arquivos
			__SetX31Mode( .F. )

			If FindFunction(cTCBuild)
				cTopBuild := &cTCBuild.()
			EndIf

			For nX := 1 To Len( aArqUpd )

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
						!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
						TcInternal( 25, "CLOB" )
					EndIf
				EndIf

				If Select( aArqUpd[nX] ) > 0
					dbSelectArea( aArqUpd[nX] )
					dbCloseArea()
				EndIf

				X31UpdTable( aArqUpd[nX] )

				If __GetX31Error()
					Alert( __GetX31Trace() )
					MsgStop( "Ocorreu um erro desconhecido durante a atualiza��o da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicion�rio e da tabela.", "ATEN��O" )
					cTexto += "Ocorreu um erro desconhecido durante a atualiza��o da estrutura da tabela : " + aArqUpd[nX] + CRLF
				EndIf

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					TcInternal( 25, "OFF" )
				EndIf

			Next nX

			//����������������������������������Ŀ
			//�Atualiza o dicion�rio SX6         �
			//������������������������������������
			oProcess:IncRegua1( "Dicion�rio de par�metros" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX6( @cTexto )

			//����������������������������������Ŀ
			//�Atualiza o dicion�rio SX9         �
			//������������������������������������
			oProcess:IncRegua1( "Dicion�rio de relacionamentos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX9( @cTexto )

			//����������������������������������Ŀ
			//�Atualiza os helps                 �
			//������������������������������������
			oProcess:IncRegua1( "Helps de Campo" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuHlp( @cTexto )

			RpcClearEnv()

		Next nI

		If MyOpenSm0(.T.)

			cAux += Replicate( "-", 128 ) + CRLF
			cAux += Replicate( " ", 128 ) + CRLF
			cAux += "LOG DA ATUALIZACAO DOS DICION�RIOS" + CRLF
			cAux += Replicate( " ", 128 ) + CRLF
			cAux += Replicate( "-", 128 ) + CRLF
			cAux += CRLF
			cAux += " Dados Ambiente" + CRLF
			cAux += " --------------------"  + CRLF
			cAux += " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt  + CRLF
			cAux += " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) + CRLF
			cAux += " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) + CRLF
			cAux += " DataBase...........: " + DtoC( dDataBase )  + CRLF
			cAux += " Data / Hora Inicio.: " + DtoC( Date() )  + " / " + Time()  + CRLF
			cAux += " Environment........: " + GetEnvServer()  + CRLF
			cAux += " StartPath..........: " + GetSrvProfString( "StartPath", "" )  + CRLF
			cAux += " RootPath...........: " + GetSrvProfString( "RootPath" , "" )  + CRLF
			cAux += " Versao.............: " + GetVersao(.T.)  + CRLF
			cAux += " Usuario TOTVS .....: " + __cUserId + " " +  cUserName + CRLF
			cAux += " Computer Name......: " + GetComputerName() + CRLF

			aInfo   := GetUserInfo()
			If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
				cAux += " "  + CRLF
				cAux += " Dados Thread" + CRLF
				cAux += " --------------------"  + CRLF
				cAux += " Usuario da Rede....: " + aInfo[nPos][1] + CRLF
				cAux += " Estacao............: " + aInfo[nPos][2] + CRLF
				cAux += " Programa Inicial...: " + aInfo[nPos][5] + CRLF
				cAux += " Environment........: " + aInfo[nPos][6] + CRLF
				cAux += " Conexao............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) )  + CRLF
			EndIf
			cAux += Replicate( "-", 128 ) + CRLF
			cAux += CRLF

			cTexto := cAux + cTexto + CRLF

			cTexto += Replicate( "-", 128 ) + CRLF
			cTexto += " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time()  + CRLF
			cTexto += Replicate( "-", 128 ) + CRLF

			cFileLog := MemoWrite( CriaTrab( , .F. ) + ".log", cTexto )

			Define Font oFont Name "Mono AS" Size 5, 12

			Define MsDialog oDlg Title "Atualizacao concluida." From 3, 0 to 340, 417 Pixel

			@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
			oMemo:bRClicked := { || AllwaysTrue() }
			oMemo:oFont     := oFont

			Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
			Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
			MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

			Activate MsDialog oDlg Center

		EndIf

	EndIf

Else

	lRet := .F.

EndIf

Return lRet


/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
��� Programa � FSAtuSX3 �                                                 ���
�������������������������������������������������������������������������͹��
��� Descricao� Funcao de processamento da gravacao do SX3 - Campos        ���
�����������������������������������������������������������������������������
*/
Static Function FSAtuSX3( cTexto )
Local aEstrut   := {}
Local aSX3      := {}
Local cAlias    := ""
Local cAliasAtu := ""
Local cMsg      := ""
Local cSeqAtu   := ""
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 0
Local nPosArq   := 0
Local nPosCpo   := 0
Local nPosOrd   := 0
Local nPosSXG   := 0
Local nPosTam   := 0
Local nSeqAtu   := 0
Local nTamSeek  := Len( SX3->X3_CAMPO )

cTexto  += "Inicio da Atualizacao" + " SX3" + CRLF + CRLF

aEstrut := { "X3_ARQUIVO", "X3_ORDEM"  , "X3_CAMPO"  , "X3_TIPO"   , "X3_TAMANHO", "X3_DECIMAL", ;
             "X3_TITULO" , "X3_TITSPA" , "X3_TITENG" , "X3_DESCRIC", "X3_DESCSPA", "X3_DESCENG", ;
             "X3_PICTURE", "X3_VALID"  , "X3_USADO"  , "X3_RELACAO", "X3_F3"     , "X3_NIVEL"  , ;
             "X3_RESERV" , "X3_CHECK"  , "X3_TRIGGER", "X3_PROPRI" , "X3_BROWSE" , "X3_VISUAL" , ;
             "X3_CONTEXT", "X3_OBRIGAT", "X3_VLDUSER", "X3_CBOX"   , "X3_CBOXSPA", "X3_CBOXENG", ;
             "X3_PICTVAR", "X3_WHEN"   , "X3_INIBRW" , "X3_GRPSXG" , "X3_FOLDER" , "X3_PYME"   }


//
// Tabela SA1
//
aAdd( aSX3, { ;
	'SA1'																	, ; //X3_ARQUIVO
	'L0'																	, ; //X3_ORDEM
	'A1_XBOL'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	1																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Emite Boleto'															, ; //X3_TITULO
	'Emite Boleto'															, ; //X3_TITSPA
	'Emite Boleto'															, ; //X3_TITENG
	'Emite Boleto?'															, ; //X3_DESCRIC
	'Emite Boleto?'															, ; //X3_DESCSPA
	'Emite Boleto?'															, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	'"1"'																	, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	'1=Sim;2=Nao'															, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		} ) //X3_PYME


//
// Tabela SE1
//
aAdd( aSX3, { ;
	'SE1'																	, ; //X3_ARQUIVO
	'N2'																	, ; //X3_ORDEM
	'E1_X_FORPG'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	3																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Forma Pagame'															, ; //X3_TITULO
	'Forma Pagame'															, ; //X3_TITSPA
	'Forma Pagame'															, ; //X3_TITENG
	'Forma de Pagamento'													, ; //X3_DESCRIC
	'Forma de Pagamento'													, ; //X3_DESCSPA
	'Forma de Pagamento'													, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'SE1'																	, ; //X3_ARQUIVO
	'N3'																	, ; //X3_ORDEM
	'E1_XDVNNUM'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	1																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Digito Verif'															, ; //X3_TITULO
	'Digito Verif'															, ; //X3_TITSPA
	'Digito Verif'															, ; //X3_TITENG
	'Digito Verificador'													, ; //X3_DESCRIC
	'Digito Verificador'													, ; //X3_DESCSPA
	'Digito Verificador'													, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		} ) //X3_PYME

//
// Tabela SEE
//
aAdd( aSX3, { ;
	'SEE'																	, ; //X3_ARQUIVO
	'48'																	, ; //X3_ORDEM
	'EE_XCART'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	3																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Carteira Cob'															, ; //X3_TITULO
	'Carteira Cob'															, ; //X3_TITSPA
	'Carteira Cob'															, ; //X3_TITENG
	'Carteira de Cobranca'													, ; //X3_DESCRIC
	'Carteira de Cobranca'													, ; //X3_DESCSPA
	'Carteira de Cobranca'													, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		} ) //X3_PYME

/*aAdd( aSX3, { ;
	'SEE'																	, ; //X3_ARQUIVO
	'49'																	, ; //X3_ORDEM
	'EE_XCODEMP'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	7																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Cod.Empresa'															, ; //X3_TITULO
	'Cod.Empresa'															, ; //X3_TITSPA
	'Cod.Empresa'															, ; //X3_TITENG
	'Cod.Empresa'															, ; //X3_DESCRIC
	'Cod.Empresa'															, ; //X3_DESCSPA
	'Cod.Empresa'															, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		} ) //X3_PYME
*/
//
// Atualizando dicion�rio
//

nPosArq := aScan( aEstrut, { |x| AllTrim( x ) == "X3_ARQUIVO" } )
nPosOrd := aScan( aEstrut, { |x| AllTrim( x ) == "X3_ORDEM"   } )
nPosCpo := aScan( aEstrut, { |x| AllTrim( x ) == "X3_CAMPO"   } )
nPosTam := aScan( aEstrut, { |x| AllTrim( x ) == "X3_TAMANHO" } )
nPosSXG := aScan( aEstrut, { |x| AllTrim( x ) == "X3_GRPSXG"  } )

aSort( aSX3,,, { |x,y| x[nPosArq]+x[nPosOrd]+x[nPosCpo] < y[nPosArq]+y[nPosOrd]+y[nPosCpo] } )

oProcess:SetRegua2( Len( aSX3 ) )

dbSelectArea( "SX3" )
dbSetOrder( 2 )
cAliasAtu := ""

For nI := 1 To Len( aSX3 )

	//
	// Verifica se o campo faz parte de um grupo e ajsuta tamanho
	//
	If !Empty( aSX3[nI][nPosSXG] )
		SXG->( dbSetOrder( 1 ) )
		If SXG->( MSSeek( aSX3[nI][nPosSXG] ) )
			If aSX3[nI][nPosTam] <> SXG->XG_SIZE
				aSX3[nI][nPosTam] := SXG->XG_SIZE
				cTexto += "O tamanho do campo " + aSX3[nI][nPosCpo] + " nao atualizado e foi mantido em ["
				cTexto += AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF
				cTexto += "   por pertencer ao grupo de campos [" + SX3->X3_GRPSXG + "]" + CRLF + CRLF
			EndIf
		EndIf
	EndIf

	SX3->( dbSetOrder( 2 ) )

	If !( aSX3[nI][nPosArq] $ cAlias )
		cAlias += aSX3[nI][nPosArq] + "/"
		aAdd( aArqUpd, aSX3[nI][nPosArq] )
	EndIf

	If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo], nTamSeek ) ) )

		//
		// Busca ultima ocorrencia do alias
		//
		If ( aSX3[nI][nPosArq] <> cAliasAtu )
			cSeqAtu   := "00"
			cAliasAtu := aSX3[nI][nPosArq]

			dbSetOrder( 1 )
			SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
			dbSkip( -1 )

			If ( SX3->X3_ARQUIVO == cAliasAtu )
				cSeqAtu := SX3->X3_ORDEM
			EndIf

			nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
		EndIf

		nSeqAtu++
		cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

		RecLock( "SX3", .T. )
		For nJ := 1 To Len( aSX3[nI] )
			If     nJ == nPosOrd  // Ordem
				FieldPut( FieldPos( aEstrut[nJ] ), cSeqAtu )

			ElseIf FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSX3[nI][nJ] )

			EndIf
		Next nJ

		dbCommit()
		MsUnLock()

		cTexto += "Criado o campo " + aSX3[nI][nPosCpo] + CRLF

	Else

		//
		// Verifica se o campo faz parte de um grupo e ajusta tamanho
		//
		If !Empty( SX3->X3_GRPSXG ) .AND. SX3->X3_GRPSXG <> aSX3[nI][nPosSXG]
			SXG->( dbSetOrder( 1 ) )
			If SXG->( MSSeek( SX3->X3_GRPSXG ) )
				If aSX3[nI][nPosTam] <> SXG->XG_SIZE
					aSX3[nI][nPosTam] := SXG->XG_SIZE
					cTexto +=  "O tamanho do campo " + aSX3[nI][nPosCpo] + " nao atualizado e foi mantido em ["
					cTexto += AllTrim( Str( SXG->XG_SIZE ) ) + "]"+ CRLF
					cTexto +=  "   por pertencer ao grupo de campos [" + SX3->X3_GRPSXG + "]" + CRLF + CRLF
				EndIf
			EndIf
		EndIf

		//
		// Verifica todos os campos
		//
		For nJ := 1 To Len( aSX3[nI] )

			//
			// Se o campo estiver diferente da estrutura
			//
			If aEstrut[nJ] == SX3->( FieldName( nJ ) ) .AND. ;
				PadR( StrTran( AllToChar( SX3->( FieldGet( nJ ) ) ), " ", "" ), 250 ) <> ;
				PadR( StrTran( AllToChar( aSX3[nI][nJ] )           , " ", "" ), 250 ) .AND. ;
				AllTrim( SX3->( FieldName( nJ ) ) ) <> "X3_ORDEM"

				cMsg := "O campo " + aSX3[nI][nPosCpo] + " est� com o " + SX3->( FieldName( nJ ) ) + ;
				" com o conte�do" + CRLF + ;
				"[" + RTrim( AllToChar( SX3->( FieldGet( nJ ) ) ) ) + "]" + CRLF + ;
				"que ser� substituido pelo NOVO conte�do" + CRLF + ;
				"[" + RTrim( AllToChar( aSX3[nI][nJ] ) ) + "]" + CRLF + ;
				"Deseja substituir ? "

				If      lTodosSim
					nOpcA := 1
				ElseIf  lTodosNao
					nOpcA := 2
				Else
					nOpcA := Aviso( "ATUALIZA��O DE DICION�RIOS E TABELAS", cMsg, { "Sim", "N�o", "Sim p/Todos", "N�o p/Todos" }, 3, "Diferen�a de conte�do - SX3" )
					lTodosSim := ( nOpcA == 3 )
					lTodosNao := ( nOpcA == 4 )

					If lTodosSim
						nOpcA := 1
						lTodosSim := MsgNoYes( "Foi selecionada a op��o de REALIZAR TODAS altera��es no SX3 e N�O MOSTRAR mais a tela de aviso." + CRLF + "Confirma a a��o [Sim p/Todos] ?" )
					EndIf

					If lTodosNao
						nOpcA := 2
						lTodosNao := MsgNoYes( "Foi selecionada a op��o de N�O REALIZAR nenhuma altera��o no SX3 que esteja diferente da base e N�O MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta a��o [N�o p/Todos]?" )
					EndIf

				EndIf

				If nOpcA == 1
					cTexto += "Alterado o campo " + aSX3[nI][nPosCpo] + CRLF
					cTexto += "   " + PadR( SX3->( FieldName( nJ ) ), 10 ) + " de [" + AllToChar( SX3->( FieldGet( nJ ) ) ) + "]" + CRLF
					cTexto += "            para [" + AllToChar( aSX3[nI][nJ] )          + "]" + CRLF + CRLF

					RecLock( "SX3", .F. )
					FieldPut( FieldPos( aEstrut[nJ] ), aSX3[nI][nJ] )
					dbCommit()
					MsUnLock()
				EndIf

			EndIf

		Next

	EndIf

	oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )

Next nI

cTexto += CRLF + "Final da Atualizacao" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF

Return NIL


/*
�����������������������������������������������������������������������������
��� Programa � FSAtuSX6 �                                                 ���
�������������������������������������������������������������������������͹��
��� Descricao� Funcao de processamento da gravacao do SX6 - Par�metros    ���
�����������������������������������������������������������������������������
*/
Static Function FSAtuSX6( cTexto )
Local aEstrut   := {}
Local aSX6      := {}
Local cAlias    := ""
Local cMsg      := ""
Local lContinua := .T.
Local lReclock  := .T.
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 0
Local nTamFil   := Len( SX6->X6_FIL )
Local nTamVar   := Len( SX6->X6_VAR )

cTexto  += "Inicio da Atualizacao" + " SX6" + CRLF + CRLF

aEstrut := { "X6_FIL"    , "X6_VAR"  , "X6_TIPO"   , "X6_DESCRIC", "X6_DSCSPA" , "X6_DSCENG" , "X6_DESC1"  , "X6_DSCSPA1",;
             "X6_DSCENG1", "X6_DESC2", "X6_DSCSPA2", "X6_DSCENG2", "X6_CONTEUD", "X6_CONTSPA", "X6_CONTENG", "X6_PROPRI" , "X6_PYME" }

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XUSFPG'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Utliza forma de pagamento customizado E1_X_FORPG'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'E1_X_FORPG'															, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XSEE'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	''																		, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'3'																		, ; //X6_CONTEUD
	'3'																		, ; //X6_CONTSPA
	'3'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XPRO001'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DESCRIC
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCSPA
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTEUD
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTSPA
	'Protestar 5 dias ap�s o Vencimento'  									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XPRO341'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DESCRIC
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCSPA
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTEUD
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTSPA
	'Protestar 5 dias ap�s o Vencimento'  									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		} ) //X6_PYME
	           
aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XPRO237'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DESCRIC
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCSPA
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTEUD
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTSPA
	'Protestar 5 dias ap�s o Vencimento'  									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		} ) //X6_PYME	
	
aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XPRO033'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DESCRIC
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCSPA
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTEUD
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTSPA
	'Protestar 5 dias ap�s o Vencimento'  									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		} ) //X6_PYME	
	
aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XPRO104'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DESCRIC
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCSPA
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTEUD
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTSPA
	'Protestar 5 dias ap�s o Vencimento'  									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		} ) //X6_PYME
	
aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XPRO653'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DESCRIC
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCSPA
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTEUD
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTSPA
	'Protestar 5 dias ap�s o Vencimento'  									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XPRO320'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DESCRIC
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCSPA
	'Descri��o Proteste Boleto Acelerador'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTEUD
	'Protestar 5 dias ap�s o Vencimento'									, ; //X6_CONTSPA
	'Protestar 5 dias ap�s o Vencimento'  									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		} ) //X6_PYME	
//
// Atualizando dicion�rio
//
oProcess:SetRegua2( Len( aSX6 ) )

dbSelectArea( "SX6" )
dbSetOrder( 1 )

For nI := 1 To Len( aSX6 )
	lContinua := .F.
	lReclock  := .F.

	If !SX6->( dbSeek( PadR( aSX6[nI][1], nTamFil ) + PadR( aSX6[nI][2], nTamVar ) ) )
		lContinua := .T.
		lReclock  := .T.
		cTexto += "Foi inclu�do o par�metro " + aSX6[nI][1] + aSX6[nI][2] + " Conte�do [" + AllTrim( aSX6[nI][13] ) + "]"+ CRLF
	EndIf

	If lContinua
		If !( aSX6[nI][1] $ cAlias )
			cAlias += aSX6[nI][1] + "/"
		EndIf

		RecLock( "SX6", lReclock )
		For nJ := 1 To Len( aSX6[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSX6[nI][nJ] )
			EndIf
		Next nJ
		dbCommit()
		MsUnLock()
	EndIf

	oProcess:IncRegua2( "Atualizando Arquivos (SX6)..." )

Next nI

cTexto += CRLF + "Final da Atualizacao" + " SX6" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF

Return NIL


/*
�����������������������������������������������������������������������������
��� Programa � FSAtuSX9 �                                                 ���
�������������������������������������������������������������������������͹��
��� Descricao� Funcao de processamento da gravacao do SX9 - Relacionament ���
�����������������������������������������������������������������������������
*/
Static Function FSAtuSX9( cTexto )
Local aEstrut   := {}
Local aSX9      := {}
Local cAlias    := ""
Local nI        := 0
Local nJ        := 0
Local nTamSeek  := Len( SX9->X9_DOM )

cTexto  += "Inicio da Atualizacao" + " SX9" + CRLF + CRLF

aEstrut := { "X9_DOM"   , "X9_IDENT"  , "X9_CDOM"   , "X9_EXPDOM", "X9_EXPCDOM" ,"X9_PROPRI", ;
             "X9_LIGDOM", "X9_LIGCDOM", "X9_CONDSQL", "X9_USEFIL", "X9_ENABLE" }

//
// Dominio SE1
//
aAdd( aSX9, { ;
	'SE1'																	, ; //X9_DOM
	'001'																	, ; //X9_IDENT
	'SK1'																	, ; //X9_CDOM
	'E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO'									, ; //X9_EXPDOM
	'K1_PREFIXO+K1_NUM+K1_PARCELA+K1_TIPO'									, ; //X9_EXPCDOM
	'S'																		, ; //X9_PROPRI
	'1'																		, ; //X9_LIGDOM
	'1'																		, ; //X9_LIGCDOM
	''																		, ; //X9_CONDSQL
	'S'																		, ; //X9_USEFIL
	'S'																		} ) //X9_ENABLE

aAdd( aSX9, { ;
	'SE1'																	, ; //X9_DOM
	'002'																	, ; //X9_IDENT
	'ACG'																	, ; //X9_CDOM
	'E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO'									, ; //X9_EXPDOM
	'ACG_PREFIX+ACG_TITULO+ACG_PARCEL+ACG_TIPO'								, ; //X9_EXPCDOM
	'S'																		, ; //X9_PROPRI
	'1'																		, ; //X9_LIGDOM
	'N'																		, ; //X9_LIGCDOM
	''																		, ; //X9_CONDSQL
	'S'																		, ; //X9_USEFIL
	'S'																		} ) //X9_ENABLE

aAdd( aSX9, { ;
	'SE1'																	, ; //X9_DOM
	'003'																	, ; //X9_IDENT
	'FIA'																	, ; //X9_CDOM
	'E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO'				, ; //X9_EXPDOM
	'FIA_CLIENT+FIA_LOJA+FIA_PREFIX+FIA_NUM+FIA_PARCEL+FIA_TIPO'			, ; //X9_EXPCDOM
	'S'																		, ; //X9_PROPRI
	'1'																		, ; //X9_LIGDOM
	'N'																		, ; //X9_LIGCDOM
	''																		, ; //X9_CONDSQL
	''																		, ; //X9_USEFIL
	''																		} ) //X9_ENABLE

aAdd( aSX9, { ;
	'SE1'																	, ; //X9_DOM
	'004'																	, ; //X9_IDENT
	'MAL'																	, ; //X9_CDOM
	'E1_PREFIXO+E1_NUM+E1_PARCELA'											, ; //X9_EXPDOM
	'MAL_PREFIX+MAL_TITULO+MAL_PARCEL'										, ; //X9_EXPCDOM
	'S'																		, ; //X9_PROPRI
	'1'																		, ; //X9_LIGDOM
	'1'																		, ; //X9_LIGCDOM
	''																		, ; //X9_CONDSQL
	''																		, ; //X9_USEFIL
	''																		} ) //X9_ENABLE

aAdd( aSX9, { ;
	'SE1'																	, ; //X9_DOM
	'005'																	, ; //X9_IDENT
	'SEV'																	, ; //X9_CDOM
	'E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO'									, ; //X9_EXPDOM
	'EV_PREFIXO+EV_NUM+EV_PARCELA+EV_TIPO'									, ; //X9_EXPCDOM
	'S'																		, ; //X9_PROPRI
	'1'																		, ; //X9_LIGDOM
	'N'																		, ; //X9_LIGCDOM
	"#EV_RECPAG ='R'"														, ; //X9_CONDSQL
	'S'																		, ; //X9_USEFIL
	'S'																		} ) //X9_ENABLE

aAdd( aSX9, { ;
	'SE1'																	, ; //X9_DOM
	'006'																	, ; //X9_IDENT
	'SEZ'																	, ; //X9_CDOM
	'E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO'									, ; //X9_EXPDOM
	'EZ_PREFIXO+EZ_NUM+EZ_PARCELA+EZ_TIPO'									, ; //X9_EXPCDOM
	'S'																		, ; //X9_PROPRI
	'1'																		, ; //X9_LIGDOM
	'N'																		, ; //X9_LIGCDOM
	"#EZ_RECPAG ='R'"														, ; //X9_CONDSQL
	'S'																		, ; //X9_USEFIL
	'S'																		} ) //X9_ENABLE

aAdd( aSX9, { ;
	'SE1'																	, ; //X9_DOM
	'007'																	, ; //X9_IDENT
	'SEF'																	, ; //X9_CDOM
	'E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA'				, ; //X9_EXPDOM
	'EF_PREFIXO+EF_TITULO+EF_PARCELA+EF_TIPO+EF_CLIENTE+EF_LOJACLI'			, ; //X9_EXPCDOM
	'S'																		, ; //X9_PROPRI
	'1'																		, ; //X9_LIGDOM
	'N'																		, ; //X9_LIGCDOM
	"#EF_CART   ='R'"														, ; //X9_CONDSQL
	'S'																		, ; //X9_USEFIL
	'S'																		} ) //X9_ENABLE

aAdd( aSX9, { ;
	'SE1'																	, ; //X9_DOM
	'008'																	, ; //X9_IDENT
	'SE6'																	, ; //X9_CDOM
	'E1_FILORIG+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO'						, ; //X9_EXPDOM
	'E6_FILORIG+E6_PREFIXO+E6_NUM+E6_PARCELA+E6_TIPO'						, ; //X9_EXPCDOM
	'S'																		, ; //X9_PROPRI
	'1'																		, ; //X9_LIGDOM
	'1'																		, ; //X9_LIGCDOM
	''																		, ; //X9_CONDSQL
	'S'																		, ; //X9_USEFIL
	'S'																		} ) //X9_ENABLE

aAdd( aSX9, { ;
	'SE1'																	, ; //X9_DOM
	'009'																	, ; //X9_IDENT
	'SEA'																	, ; //X9_CDOM
	'E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO'						, ; //X9_EXPDOM
	'EA_FILORIG+EA_PREFIXO+EA_NUM+EA_PARCELA+EA_TIPO'						, ; //X9_EXPCDOM
	'S'																		, ; //X9_PROPRI
	'1'																		, ; //X9_LIGDOM
	'1'																		, ; //X9_LIGCDOM
	"#EA_CART   ='R'"														, ; //X9_CONDSQL
	'N'																		, ; //X9_USEFIL
	'S'																		} ) //X9_ENABLE

//
// Atualizando dicion�rio
//
oProcess:SetRegua2( Len( aSX9 ) )

dbSelectArea( "SX9" )
dbSetOrder( 2 )

For nI := 1 To Len( aSX9 )

	If !SX9->( dbSeek( PadR( aSX9[nI][3], nTamSeek ) + PadR( aSX9[nI][1], nTamSeek ) ) )

		If !( aSX9[nI][1]+aSX9[nI][3] $ cAlias )
			cAlias += aSX9[nI][1]+aSX9[nI][3] + "/"
		EndIf

		RecLock( "SX9", .T. )
		For nJ := 1 To Len( aSX9[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSX9[nI][nJ] )
			EndIf
		Next nJ
		dbCommit()
		MsUnLock()

		cTexto += "Foi inclu�do o relacionamento " + aSX9[nI][1] + "/" + aSX9[nI][3] + CRLF

		oProcess:IncRegua2( "Atualizando Arquivos (SX9)..." )

	EndIf

Next nI

cTexto += CRLF + "Final da Atualizacao" + " SX9" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF

Return NIL


/*
�����������������������������������������������������������������������������
��� Programa � FSAtuHlp �                                                 ���
�������������������������������������������������������������������������͹��
��� Descricao� Funcao de processamento da gravacao dos Helps de Campos    ���
�����������������������������������������������������������������������������
*/
Static Function FSAtuHlp( cTexto )
Local aHlpPor   := {}
Local aHlpEng   := {}
Local aHlpSpa   := {}

cTexto  += "Inicio da Atualizacao" + " " + "Helps de Campos" + CRLF + CRLF


oProcess:IncRegua2( "Atualizando Helps de Campos ..." )

//
// Helps Tabela SE1
//
aHlpPor := {}
aAdd( aHlpPor, 'Forma de pagamento' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PE1_X_FORPG", aHlpPor, aHlpEng, aHlpSpa, .T. )
cTexto += "Atualizado o Help do campo " + "E1_X_FORPG" + CRLF

aHlpPor := {}
aAdd( aHlpPor, 'Digito Verificador' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PE1_XDVNNUM", aHlpPor, aHlpEng, aHlpSpa, .T. )
cTexto += "Atualizado o Help do campo " + "E1_XDVNNUM" + CRLF

//
// Helps Tabela SEE
//
aHlpPor := {}
aAdd( aHlpPor, 'Carteira de Cobran�a' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PEE_XCART  ", aHlpPor, aHlpEng, aHlpSpa, .T. )
cTexto += "Atualizado o Help do campo " + "EE_XCART" + CRLF

aHlpPor := {}
aAdd( aHlpPor, 'Cod.Empresa' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PEE_XCODEMP", aHlpPor, aHlpEng, aHlpSpa, .T. )
cTexto += "Atualizado o Help do campo " + "EE_XCODEMP" + CRLF

cTexto += CRLF + "Final da Atualizacao" + " " + "Helps de Campos" + CRLF + Replicate( "-", 128 ) + CRLF + CRLF

Return {}


/*
�����������������������������������������������������������������������������
���Rotina    �ESCEMPRESA�                                                 ���
�������������������������������������������������������������������������͹��
���Descricao � Funcao Generica para escolha de Empresa, montado pelo SM0_ ���
���          � Retorna vetor contendo as selecoes feitas.                 ���
���          � Se nao For marcada nenhuma o vetor volta vazio.            ���
�������������������������������������������������������������������������͹��
�����������������������������������������������������������������������������
*/
Static Function EscEmpresa()
//��������������������������������������������Ŀ
//� Parametro  nTipo                           �
//� 1  - Monta com Todas Empresas/Filiais      �
//� 2  - Monta so com Empresas                 �
//� 3  - Monta so com Filiais de uma Empresa   �
//�                                            �
//� Parametro  aMarcadas                       �
//� Vetor com Empresas/Filiais pre marcadas    �
//�                                            �
//� Parametro  cEmpSel                         �
//� Empresa que sera usada para montar selecao �
//����������������������������������������������
Local   aSalvAmb := GetArea()
Local   aSalvSM0 := {}
Local   aRet     := {}
Local   aVetor   := {}
Local   oDlg     := NIL
Local   oChkMar  := NIL
Local   oLbx     := NIL
Local   oMascEmp := NIL
Local   oMascFil := NIL
Local   oButMarc := NIL
Local   oButDMar := NIL
Local   oButInv  := NIL
Local   oSay     := NIL
Local   oOk      := LoadBitmap( GetResources(), "LBOK" )
Local   oNo      := LoadBitmap( GetResources(), "LBNO" )
Local   lChk     := .F.
Local   lOk      := .F.
Local   lTeveMarc:= .F.
Local   cVar     := ""
Local   cNomEmp  := ""
Local   cMascEmp := "??"
Local   cMascFil := "??"

Local   aMarcadas  := {}


If !MyOpenSm0(.F.)
	Return aRet
EndIf


dbSelectArea( "SM0" )
aSalvSM0 := SM0->( GetArea() )
dbSetOrder( 1 )
dbGoTop()

While !SM0->( EOF() )

	If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
		aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
	EndIf

	dbSkip()
End

RestArea( aSalvSM0 )

Define MSDialog  oDlg Title "" From 0, 0 To 270, 396 Pixel

oDlg:cToolTip := "Tela para M�ltiplas Sele��es de Empresas/Filiais"

oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualiza��o"

@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
oLbx:SetArray(  aVetor )
oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
aVetor[oLbx:nAt, 2], ;
aVetor[oLbx:nAt, 4]}}
oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
oLbx:cToolTip   :=  oDlg:cTitle
oLbx:lHScroll   := .F. // NoScroll

@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos"   Message  Size 40, 007 Pixel Of oDlg;
on Click MarcaTodos( lChk, @aVetor, oLbx )

@ 123, 10 Button oButInv Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Inverter Sele��o" Of oDlg

// Marca/Desmarca por mascara
@ 113, 51 Say  oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
@ 112, 80 MSGet  oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), cMascFil := StrTran( cMascFil, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
Message "M�scara Empresa ( ?? )"  Of oDlg
@ 123, 50 Button oButMarc Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Marcar usando m�scara ( ?? )"    Of oDlg
@ 123, 80 Button oButDMar Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Desmarcar usando m�scara ( ?? )" Of oDlg

Define SButton From 111, 125 Type 1 Action ( RetSelecao( @aRet, aVetor ), oDlg:End() ) OnStop "Confirma a Sele��o"  Enable Of oDlg
Define SButton From 111, 158 Type 2 Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) OnStop "Abandona a Sele��o" Enable Of oDlg
Activate MSDialog  oDlg Center

RestArea( aSalvAmb )
dbSelectArea( "SM0" )
dbCloseArea()

Return  aRet


/*
�����������������������������������������������������������������������������
���Rotina    �MARCATODOS�                                                 ���
�������������������������������������������������������������������������͹��
���Descricao � Funcao Auxiliar para marcar/desmarcar todos os itens do    ���
���          � ListBox ativo                                              ���
�����������������������������������������������������������������������������
*/
Static Function MarcaTodos( lMarca, aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := lMarca
Next nI

oLbx:Refresh()

Return NIL


/*
�����������������������������������������������������������������������������
���Rotina    �INVSELECAO�                                                 ���
�������������������������������������������������������������������������͹��
���Descricao � Funcao Auxiliar para inverter selecao do ListBox Ativo     ���
�����������������������������������������������������������������������������
*/
Static Function InvSelecao( aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := !aVetor[nI][1]
Next nI

oLbx:Refresh()

Return NIL


/*
�����������������������������������������������������������������������������
���Rotina    �RETSELECAO�                                                 ���
�������������������������������������������������������������������������͹��
���Descricao � Funcao Auxiliar que monta o retorno com as selecoes        ���
�����������������������������������������������������������������������������
*/
Static Function RetSelecao( aRet, aVetor )
Local  nI    := 0

aRet := {}
For nI := 1 To Len( aVetor )
	If aVetor[nI][1]
		aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
	EndIf
Next nI

Return NIL


/*
�����������������������������������������������������������������������������
���Rotina    � MARCAMAS �                                                 ���
�������������������������������������������������������������������������͹��
���Descricao � Funcao para marcar/desmarcar usando mascaras               ���
�����������������������������������������������������������������������������
*/
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
Local cPos1 := SubStr( cMascEmp, 1, 1 )
Local cPos2 := SubStr( cMascEmp, 2, 1 )
Local nPos  := oLbx:nAt
Local nZ    := 0

For nZ := 1 To Len( aVetor )
	If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
		If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
			aVetor[nZ][1] :=  lMarDes
		EndIf
	EndIf
Next

oLbx:nAt := nPos
oLbx:Refresh()

Return NIL


/*
�����������������������������������������������������������������������������
���Rotina    � VERTODOS �                                                 ���
�������������������������������������������������������������������������͹��
���Descricao � Funcao auxiliar para verificar se estao todos marcardos    ���
���          � ou nao                                                     ���
�����������������������������������������������������������������������������
*/
Static Function VerTodos( aVetor, lChk, oChkMar )
Local lTTrue := .T.
Local nI     := 0

For nI := 1 To Len( aVetor )
	lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
Next nI

lChk := IIf( lTTrue, .T., .F. )
oChkMar:Refresh()

Return NIL


/*
�����������������������������������������������������������������������������
�������������������������������������������������������������������������͹��
��� Descricao� Funcao de processamento abertura do SM0 modo exclusivo     ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
��� Uso      � MyOpenSM0  - Gerado por EXPORDIC / Upd. V.4.10.6 EFS       ���
�����������������������������������������������������������������������������
*/
Static Function MyOpenSM0(lShared)

Local lOpen := .F.
Local nLoop := 0

For nLoop := 1 To 20
	dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )

	If !Empty( Select( "SM0" ) )
		lOpen := .T.
		dbSetIndex( "SIGAMAT.IND" )
		Exit
	EndIf

	Sleep( 500 )

Next nLoop

If !lOpen
	MsgStop( "N�o foi poss�vel a abertura da tabela " + ;
	IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATEN��O" )
EndIf

Return lOpen


/////////////////////////////////////////////////////////////////////////////
