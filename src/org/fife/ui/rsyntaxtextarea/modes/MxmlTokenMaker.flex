/*
 * 01/21/2011
 *
 * MxmlTokenMaker.java - Generates tokens for MXML syntax highlighting.
 * 
 * This library is distributed under a modified BSD license.  See the included
 * RSyntaxTextArea.License.txt file for details.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * Scanner for MXML.
 *
 * This implementation was created using
 * <a href="http://www.jflex.de/">JFlex</a> 1.4.1; however, the generated file
 * was modified for performance.  Memory allocation needs to be almost
 * completely removed to be competitive with the handwritten lexers (subclasses
 * of <code>AbstractTokenMaker</code>, so this class has been modified so that
 * Strings are never allocated (via yytext()), and the scanner never has to
 * worry about refilling its buffer (needlessly copying chars around).
 * We can achieve this because RText always scans exactly 1 line of tokens at a
 * time, and hands the scanner this line as an array of characters (a Segment
 * really).  Since tokens contain pointers to char arrays instead of Strings
 * holding their contents, there is no need for allocating new memory for
 * Strings.<p>
 *
 * The actual algorithm generated for scanning has, of course, not been
 * modified.<p>
 *
 * If you wish to regenerate this file yourself, keep in mind the following:
 * <ul>
 *   <li>The generated <code>MXMLTokenMaker.java</code> file will contain two
 *       definitions of both <code>zzRefill</code> and <code>yyreset</code>.
 *       You should hand-delete the second of each definition (the ones
 *       generated by the lexer), as these generated methods modify the input
 *       buffer, which we'll never have to do.</li>
 *   <li>You should also change the declaration/definition of zzBuffer to NOT
 *       be initialized.  This is a needless memory allocation for us since we
 *       will be pointing the array somewhere else anyway.</li>
 *   <li>You should NOT call <code>yylex()</code> on the generated scanner
 *       directly; rather, you should use <code>getTokenList</code> as you would
 *       with any other <code>TokenMaker</code> instance.</li>
 * </ul>
 *
 * @author Robert Futrell
 * @version 0.5
 *
 */
%%

%public
%class MxmlTokenMaker
%extends AbstractMarkupTokenMaker
%unicode
%type org.fife.ui.rsyntaxtextarea.Token


%{

	/**
	 * Type specific to JSPTokenMaker denoting a line ending with an unclosed
	 * double-quote attribute.
	 */
	public static final int INTERNAL_ATTR_DOUBLE			= -1;


	/**
	 * Type specific to JSPTokenMaker denoting a line ending with an unclosed
	 * single-quote attribute.
	 */
	public static final int INTERNAL_ATTR_SINGLE			= -2;


	/**
	 * Token type specific to this class; this signals that the user has
	 * ended a line with an unclosed XML tag; thus a new line is beginning
	 * still inside of the tag.
	 */
	public static final int INTERNAL_INTAG						= -3;

	/**
	 * Token type specific to this class; this signals that the user has
	 * ended a line with an unclosed Script tag; thus a new line is beginning
	 * still inside of the tag.
	 */
	public static final int INTERNAL_INTAG_SCRIPT				= -4;

	/**
	 * Token type specific to this class; this signals that the user has
	 * ended a line in the middle of a double-quoted attribute in a Script
	 * tag.
	 */
	public static final int INTERNAL_ATTR_DOUBLE_QUOTE_SCRIPT	= -5;

	/**
	 * Token type specific to this class; this signals that the user has
	 * ended a line in the middle of a single-quoted attribute in a Script
	 * tag.
	 */
	public static final int INTERNAL_ATTR_SINGLE_QUOTE_SCRIPT	= -6;

	/**
	 * Token type specific to this class; this signals that the user has
	 * ended a line in an ActionScript code block (text content inside a
	 * Script tag).
	 */
	public static final int INTERNAL_IN_AS						= -7;

	/**
	 * Token type specific to this class; this signals that the user has
	 * ended a line in an MLC in an ActionScript code block (text content
	 * inside a Script tag).
	 */
	public static final int INTERNAL_IN_AS_MLC					= -8;

	/**
	 * Whether closing markup tags are automatically completed for HTML.
	 */
	private static boolean completeCloseTags;


	/**
	 * Constructor.  This must be here because JFlex does not generate a
	 * no-parameter constructor.
	 */
	public MxmlTokenMaker() {
	}


	static {
		completeCloseTags = true;
	}


	/**
	 * Adds the token specified to the current linked list of tokens as an
	 * "end token;" that is, at <code>zzMarkedPos</code>.
	 *
	 * @param tokenType The token's type.
	 */
	private void addEndToken(int tokenType) {
		addToken(zzMarkedPos,zzMarkedPos, tokenType);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 * @see #addToken(int, int, int)
	 */
	private void addHyperlinkToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so, true);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int tokenType) {
		addToken(zzStartRead, zzMarkedPos-1, tokenType);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param array The character array.
	 * @param start The starting offset in the array.
	 * @param end The ending offset in the array.
	 * @param tokenType The token's type.
	 * @param startOffset The offset in the document at which this token
	 *                    occurs.
	 * @param hyperlink Whether this token is a hyperlink.
	 */
	public void addToken(char[] array, int start, int end, int tokenType,
						int startOffset, boolean hyperlink) {
		super.addToken(array, start,end, tokenType, startOffset, hyperlink);
		zzStartRead = zzMarkedPos;
	}


	/**
	 * Returns whether markup close tags should be completed.  For XML, the
	 * default value is <code>true</code>.
	 *
	 * @return Whether closing markup tags are completed.
	 * @see #setCompleteCloseTags(boolean)
	 */
	public boolean getCompleteCloseTags() {
		return completeCloseTags;
	}


	/**
	 * Static version of {@link #getCompleteCloseTags()}.  This hack is
	 * unfortunately needed for applications to be able to query this value
	 * without instantiating this class.
	 *
	 * @return Whether closing markup tags are completed.
	 * @see #setCompleteCloseTags(boolean)
	 */
	public static boolean getCompleteCloseMarkupTags() {
		return completeCloseTags;
	}


	/**
	 * Always returns <tt>false</tt>, as you never want "mark occurrences"
	 * working in XML files.
	 *
	 * @param type The token type.
	 * @return Whether tokens of this type should have "mark occurrences"
	 *         enabled.
	 */
	public boolean getMarkOccurrencesOfTokenType(int type) {
		return false;
	}


	/**
	 * Returns the first token in the linked list of tokens generated
	 * from <code>text</code>.  This method must be implemented by
	 * subclasses so they can correctly implement syntax highlighting.
	 *
	 * @param text The text from which to get tokens.
	 * @param initialTokenType The token type we should start with.
	 * @param startOffset The offset into the document at which
	 *        <code>text</code> starts.
	 * @return The first <code>Token</code> in a linked list representing
	 *         the syntax highlighted text.
	 */
	public Token getTokenList(Segment text, int initialTokenType, int startOffset) {

		resetTokenList();
		this.offsetShift = -text.offset + startOffset;

		// Start off in the proper state.
		int state = Token.NULL;
		switch (initialTokenType) {
			case Token.COMMENT_MULTILINE:
				state = COMMENT;
				start = text.offset;
				break;
			case Token.FUNCTION:
				state = DTD;
				start = text.offset;
				break;
			case INTERNAL_ATTR_DOUBLE:
				state = INATTR_DOUBLE;
				start = text.offset;
				break;
			case INTERNAL_ATTR_SINGLE:
				state = INATTR_SINGLE;
				start = text.offset;
				break;
			case Token.MARKUP_PROCESSING_INSTRUCTION:
				state = PI;
				start = text.offset;
				break;
			case INTERNAL_INTAG:
				state = INTAG;
				start = text.offset;
				break;
			case INTERNAL_INTAG_SCRIPT:
				state = INTAG_SCRIPT;
				start = text.offset;
				break;
			case INTERNAL_ATTR_DOUBLE_QUOTE_SCRIPT:
				state = INATTR_DOUBLE_SCRIPT;
				start = text.offset;
				break;
			case INTERNAL_ATTR_SINGLE_QUOTE_SCRIPT:
				state = INATTR_SINGLE_SCRIPT;
				start = text.offset;
				break;
			case INTERNAL_IN_AS:
				state = AS;
				start = text.offset;
				break;
			case INTERNAL_IN_AS_MLC:
				state = AS_MLC;
				start = text.offset;
				break;
			case Token.MARKUP_CDATA:
				state = CDATA;
				start = text.offset;
				break;
			default:
				state = Token.NULL;
		}

		s = text;
		try {
			yyreset(zzReader);
			yybegin(state);
			return yylex();
		} catch (IOException ioe) {
			ioe.printStackTrace();
			return new DefaultToken();
		}

	}


	/**
	 * Sets whether markup close tags should be completed.
	 *
	 * @param complete Whether closing markup tags are completed.
	 * @see #getCompleteCloseTags()
	 */
	public static void setCompleteCloseTags(boolean complete) {
		completeCloseTags = complete;
	}


	/**
	 * Refills the input buffer.
	 *
	 * @return      <code>true</code> if EOF was reached, otherwise
	 *              <code>false</code>.
	 */
	private boolean zzRefill() {
		return zzCurrentPos>=s.offset+s.count;
	}


	/**
	 * Resets the scanner to read from a new input stream.
	 * Does not close the old reader.
	 *
	 * All internal variables are reset, the old input stream 
	 * <b>cannot</b> be reused (internal buffer is discarded and lost).
	 * Lexical state is set to <tt>YY_INITIAL</tt>.
	 *
	 * @param reader   the new input stream 
	 */
	public final void yyreset(java.io.Reader reader) {
		// 's' has been updated.
		zzBuffer = s.array;
		/*
		 * We replaced the line below with the two below it because zzRefill
		 * no longer "refills" the buffer (since the way we do it, it's always
		 * "full" the first time through, since it points to the segment's
		 * array).  So, we assign zzEndRead here.
		 */
		//zzStartRead = zzEndRead = s.offset;
		zzStartRead = s.offset;
		zzEndRead = zzStartRead + s.count - 1;
		zzCurrentPos = zzMarkedPos = zzPushbackPos = s.offset;
		zzLexicalState = YYINITIAL;
		zzReader = reader;
		zzAtBOL  = true;
		zzAtEOF  = false;
	}


%}

/* XML macros (and some building-block macros used by AS macros). */
Letter				= [A-Za-z]
NonzeroDigit		= [1-9]
Digit				= ("0"|{NonzeroDigit})
LetterOrUnderscore	= ({Letter}|"_")
NameStartChar		= ({Letter}|[\:])
NameChar			= ({NameStartChar}|[\-\.]|{Digit})
TagName				= ({NameStartChar}{NameChar}*)
Whitespace			= ([ \t\f])
LineTerminator			= ([\n])
Identifier			= ([^ \t\n<&]+)
AmperItem				= ([&][^; \t]*[;]?)
InTagIdentifier		= ([^ \t\n\"\'=\/>]+)
CDataBegin			= ("<![CDATA[")
CDataEnd				= ("]]>")


/* ActionScript macros. */
HexDigit							= ({Digit}|[A-Fa-f])
OctalDigit						= ([0-7])
AnyCharacterButApostropheOrBackSlash	= ([^\\'])
AnyCharacterButDoubleQuoteOrBackSlash	= ([^\\\"\n])
EscapedSourceCharacter				= ("u"{HexDigit}{HexDigit}{HexDigit}{HexDigit})
Escape							= ("\\"(([btnfr\"'\\])|([0123]{OctalDigit}?{OctalDigit}?)|({OctalDigit}{OctalDigit}?)|{EscapedSourceCharacter}))
NonSeparator						= ([^\t\f\r\n\ \(\)\{\}\[\]\;\,\.\=\>\<\!\~\?\:\+\-\*\/\&\|\^\%\"\']|"#"|"\\")
IdentifierStart					= ({LetterOrUnderscore}|"$")
IdentifierPart						= ({IdentifierStart}|{Digit}|("\\"{EscapedSourceCharacter}))

AS_CharLiteral				= ([\']({AnyCharacterButApostropheOrBackSlash}|{Escape})*[\'])
AS_UnclosedCharLiteral		= ([\']([\\].|[^\\\'])*[^\']?)
AS_ErrorCharLiteral			= ({AS_UnclosedCharLiteral}[\'])
AS_StringLiteral			= ([\"]({AnyCharacterButDoubleQuoteOrBackSlash}|{Escape})*[\"])
AS_UnclosedStringLiteral	= ([\"]([\\].|[^\\\"])*[^\"]?)
AS_ErrorStringLiteral		= ({AS_UnclosedStringLiteral}[\"])

AS_MLCBegin					= ("/*")
AS_MLCEnd					= ("*/")
AS_LineCommentBegin			= ("//")
IntegerHelper1				= (({NonzeroDigit}{Digit}*)|"0")
IntegerHelper2				= ("0"(([xX]{HexDigit}+)|({OctalDigit}*)))
AS_IntegerLiteral			= ({IntegerHelper1}[lL]?)
AS_HexLiteral				= ({IntegerHelper2}[lL]?)
FloatHelper1				= ([fFdD]?)
FloatHelper2				= ([eE][+-]?{Digit}+{FloatHelper1})
FloatLiteral1				= ({Digit}+"."({FloatHelper1}|{FloatHelper2}|{Digit}+({FloatHelper1}|{FloatHelper2})))
FloatLiteral2				= ("."{Digit}+({FloatHelper1}|{FloatHelper2}))
FloatLiteral3				= ({Digit}+{FloatHelper2})
AS_FloatLiteral				= ({FloatLiteral1}|{FloatLiteral2}|{FloatLiteral3}|({Digit}+[fFdD]))
AS_ErrorNumberFormat		= (({AS_IntegerLiteral}|{AS_HexLiteral}|{AS_FloatLiteral}){NonSeparator}+)
AS_BooleanLiteral			= ("true"|"false")

AS_Separator				= ([\(\)\{\}\[\]])
AS_Separator2				= ([\;,.])

NonAssignmentOperator		= ("+"|"-"|"<="|"^"|"++"|"<"|"*"|">="|"%"|"--"|">"|"/"|"!="|"?"|">>"|"!"|"&"|"=="|":"|">>"|"~"|"|"|"&&"|">>>")
AssignmentOperator			= ("="|"-="|"*="|"/="|"|="|"&="|"^="|"+="|"%="|"<<="|">>="|">>>=")
AS_Operator					= ({NonAssignmentOperator}|{AssignmentOperator})

AS_Identifier				= ({IdentifierStart}{IdentifierPart}*)
AS_ErrorIdentifier			= ({NonSeparator}+)
AS_EndScriptTag				= ("</"({NameStartChar}{NameChar}*":")?"Script"{Whitespace}*">")

URLGenDelim				= ([:\/\?#\[\]@])
URLSubDelim				= ([\!\$&'\(\)\*\+,;=])
URLUnreserved			= ({LetterOrUnderscore}|{Digit}|[\-\.\~])
URLCharacter			= ({URLGenDelim}|{URLSubDelim}|{URLUnreserved}|[%])
URLCharacters			= ({URLCharacter}*)
URLEndCharacter			= ([\/\$]|{Letter}|{Digit})
URL						= (((https?|f(tp|ile))"://"|"www.")({URLCharacters}{URLEndCharacter})?)

%state COMMENT
%state PI
%state DTD
%state INTAG
%state INATTR_DOUBLE
%state INATTR_SINGLE
%state INTAG_SCRIPT
%state INATTR_DOUBLE_SCRIPT
%state INATTR_SINGLE_SCRIPT
%state CDATA

%state AS
%state AS_MLC
%state AS_EOL_COMMENT

%%

<YYINITIAL> {
	"<!--"						{ start = zzMarkedPos-4; yybegin(COMMENT); }
	{CDataBegin}					{ addToken(Token.DATA_TYPE); start = zzMarkedPos; yybegin(CDATA); }
	"<!"							{ start = zzMarkedPos-2; yybegin(DTD); }
	"<?"							{ start = zzMarkedPos-2; yybegin(PI); }
	"<"{TagName}				{
									int count = yylength();
									String tag = yytext(); // Get before addToken calls
									addToken(zzStartRead,zzStartRead, Token.MARKUP_TAG_DELIMITER);
									addToken(zzMarkedPos-(count-1), zzMarkedPos-1, Token.MARKUP_TAG_NAME);
									if (tag.endsWith(":Script") || tag.equals("<Script")) {
										yybegin(INTAG_SCRIPT);
									}
									else {
										yybegin(INTAG);
									}
								}
	"</"{TagName}				{
									int count = yylength();
									addToken(zzStartRead,zzStartRead+1, Token.MARKUP_TAG_DELIMITER);
									addToken(zzMarkedPos-(count-2), zzMarkedPos-1, Token.MARKUP_TAG_NAME);
									yybegin(INTAG);
								}
	"<"							{ addToken(Token.MARKUP_TAG_DELIMITER); yybegin(INTAG); }
	"</"						{ addToken(Token.MARKUP_TAG_DELIMITER); yybegin(INTAG); }
	{LineTerminator}				{ addNullToken(); return firstToken; }
	{Identifier}					{ addToken(Token.IDENTIFIER); }
	{AmperItem}					{ addToken(Token.DATA_TYPE); }
	{Whitespace}+					{ addToken(Token.WHITESPACE); }
	<<EOF>>						{ addNullToken(); return firstToken; }
}

<COMMENT> {
	[^\n\-]+						{}
	{LineTerminator}				{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); return firstToken; }
	"-->"						{ yybegin(YYINITIAL); addToken(start,zzStartRead+2, Token.COMMENT_MULTILINE); }
	"-"							{}
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); return firstToken; }
}

<PI> {
	[^\n\?]+						{}
	{LineTerminator}				{ addToken(start,zzStartRead-1, Token.MARKUP_PROCESSING_INSTRUCTION); return firstToken; }
	"?>"							{ yybegin(YYINITIAL); addToken(start,zzStartRead+1, Token.MARKUP_PROCESSING_INSTRUCTION); }
	"?"							{}
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.MARKUP_PROCESSING_INSTRUCTION); return firstToken; }
}

<DTD> {
	[^\n>]+					{}
	{LineTerminator}			{ addToken(start,zzStartRead-1, Token.FUNCTION); return firstToken; }
	">"						{ yybegin(YYINITIAL); addToken(start,zzStartRead, Token.FUNCTION); }
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.FUNCTION); return firstToken; }
}

<INTAG> {
	{InTagIdentifier}				{ addToken(Token.MARKUP_TAG_ATTRIBUTE); }
	{Whitespace}+					{ addToken(Token.WHITESPACE); }
	"="							{ addToken(Token.OPERATOR); }
	"/"							{ addToken(Token.MARKUP_TAG_DELIMITER); /* Not valid but we'll still accept it */ }
	"/>"						{ yybegin(YYINITIAL); addToken(Token.MARKUP_TAG_DELIMITER); }
	">"							{ yybegin(YYINITIAL); addToken(Token.MARKUP_TAG_DELIMITER); }
	[\"]						{ start = zzMarkedPos-1; yybegin(INATTR_DOUBLE); }
	[\']						{ start = zzMarkedPos-1; yybegin(INATTR_SINGLE); }
	<<EOF>>						{ addToken(start,zzStartRead-1, INTERNAL_INTAG); return firstToken; }
}

<INATTR_DOUBLE> {
	[^\"]*						{}
	[\"]						{ yybegin(INTAG); addToken(start,zzStartRead, Token.MARKUP_TAG_ATTRIBUTE_VALUE); }
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.MARKUP_TAG_ATTRIBUTE_VALUE); addEndToken(INTERNAL_ATTR_DOUBLE); return firstToken; }
}

<INATTR_SINGLE> {
	[^\']*						{}
	[\']						{ yybegin(INTAG); addToken(start,zzStartRead, Token.MARKUP_TAG_ATTRIBUTE_VALUE); }
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.MARKUP_TAG_ATTRIBUTE_VALUE); addEndToken(INTERNAL_ATTR_SINGLE); return firstToken; }
}

<INTAG_SCRIPT> {
	{InTagIdentifier}				{ addToken(Token.MARKUP_TAG_ATTRIBUTE); }
	{Whitespace}+					{ addToken(Token.WHITESPACE); }
	"="							{ addToken(Token.OPERATOR); }
	"/"							{ addToken(Token.MARKUP_TAG_DELIMITER); /* Not valid but we'll still accept it */ }
	"/>"						{ yybegin(YYINITIAL); addToken(Token.MARKUP_TAG_DELIMITER); }
	">"							{ yybegin(AS); addToken(Token.MARKUP_TAG_DELIMITER); }
	[\"]						{ start = zzMarkedPos-1; yybegin(INATTR_DOUBLE_SCRIPT); }
	[\']						{ start = zzMarkedPos-1; yybegin(INATTR_SINGLE_SCRIPT); }
	<<EOF>>						{ addToken(start,zzStartRead-1, INTERNAL_INTAG_SCRIPT); return firstToken; }
}

<INATTR_DOUBLE_SCRIPT> {
	[^\"]*						{}
	[\"]						{ yybegin(INTAG_SCRIPT); addToken(start,zzStartRead, Token.MARKUP_TAG_ATTRIBUTE_VALUE); }
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.MARKUP_TAG_ATTRIBUTE_VALUE); addEndToken(INTERNAL_ATTR_DOUBLE_QUOTE_SCRIPT); return firstToken; }
}

<INATTR_SINGLE_SCRIPT> {
	[^\']*						{}
	[\']						{ yybegin(INTAG_SCRIPT); addToken(start,zzStartRead, Token.MARKUP_TAG_ATTRIBUTE_VALUE); }
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.MARKUP_TAG_ATTRIBUTE_VALUE); addEndToken(INTERNAL_ATTR_SINGLE_QUOTE_SCRIPT); return firstToken; }
}

<CDATA> {
	[^\]]+						{}
	{CDataEnd}					{ int temp=zzStartRead; yybegin(YYINITIAL); addToken(start,zzStartRead-1, Token.MARKUP_CDATA); addToken(temp,zzMarkedPos-1, Token.DATA_TYPE); }
	"]"							{}
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.MARKUP_CDATA); return firstToken; }
}

<AS> {

	{AS_EndScriptTag}			{
								  int origStart = zzStartRead;
								  String text = yytext();
								  int tagNameEnd = text.length() - 2; // "-1" is '>'
								  while (Character.isWhitespace(text.charAt(tagNameEnd))) {
								      tagNameEnd--;
								  }
								  int tagNameLen = tagNameEnd - 1;
								  yybegin(YYINITIAL);
								  addToken(zzStartRead,zzStartRead+1, Token.MARKUP_TAG_DELIMITER);
								  addToken(origStart+2,origStart+2+tagNameLen-1, Token.MARKUP_TAG_NAME);
								  if (tagNameEnd<text.length()-2) {
								      addToken(origStart+tagNameEnd+1, zzMarkedPos-2, Token.WHITESPACE);
								  }
								  addToken(zzMarkedPos-1,zzMarkedPos-1, Token.MARKUP_TAG_DELIMITER);
								}

	/* ActionScript snippets are usually wrapped in CDATA. */
	{CDataBegin} |
	{CDataEnd}					{ addToken(Token.DATA_TYPE); }
	
	/* Keywords */
	"add" |
	"and" |
	"break" |
	"case" |
	"catch" |
	"class" |
	"const" |
	"continue" |
	"default" |
	"delete" |
	"do" |
	"dynamic" |
	"else" |
	"eq" |
	"extends" |
	"final" |
	"finally" |
	"for" |
	"for each" |
	"function" |
	"ge" |
	"get" |
	"gt" |
	"if" |
	"ifFrameLoaded" |
	"implements" |
	"import" |
	"in" |
	"include" |
	"interface" |
	"internal" |
	"label" |
	"le" |
	"lt" |
	"namespace" |
	"native" |
	"ne" |
	"new" |
	"not" |
	"on" |
	"onClipEvent" |
	"or" |
	"override" |
	"package" |
	"private" |
	"protected" |
	"public" |
	"return" |
	"set" |
	"static" |
	"super" |
	"switch" |
	"tellTarget" |
	"this" |
	"throw" |
	"try" |
	"typeof" |
	"use" |
	"var" |
	"void" |
	"while" |
	"with" |

	"null" |
	"undefined"				{ addToken(Token.RESERVED_WORD); }

	/* Built-in objects (good idea not to use these names!) */
	"Array" |
	"Boolean" |
	"Color" |
	"Date" |
	"Function" |
	"int" |
	"Key" |
	"MovieClip" |
	"Math" |
	"Mouse" |
	"Null" |
	"Number" |
	"Object" |
	"Selection" |
	"Sound" |
	"String" |
	"uint" |
	"Vector" |
	"void" |
	"XML" |
	"XMLNode" |
	"XMLSocket"			{ addToken(Token.DATA_TYPE); }

	/* Global functions */
	"call" |
	"escape" |
	"eval" |
	"fscommand" |
	"getProperty" |
	"getTimer" |
	"getURL" |
	"getVersion" |
	"gotoAndPlay" |
	"gotoAndStop" |
	"#include" |
	"int" |
	"isFinite" |
	"isNaN" |
	"loadMovie" |
	"loadMovieNum" |
	"loadVariables" |
	"loadVariablesNum" |
	"maxscroll" |
	"newline" |
	"nextFrame" |
	"nextScene" |
	"Number" |
	"parseFloat" |
	"parseInt" |
	"play" |
	"prevFrame" |
	"prevScene" |
	"print" |
	"printAsBitmap" |
	"printAsBitmapNum" |
	"printNum" |
	"random" |
	"removeMovieClip" |
	"scroll" |
	"setProperty" |
	"startDrag" |
	"stop" |
	"stopAllSounds" |
	"stopDrag" |
	"String" |
	"targetPath" |
	"tellTarget" |
	"toggleHighQuality" |
	"trace" |
	"unescape" |
	"unloadMovie" |
	"unloadMovieNum" |
	"updateAfterEvent"			{ addToken(Token.FUNCTION); }

	/* Booleans. */
	{AS_BooleanLiteral}			{ addToken(Token.LITERAL_BOOLEAN); }

	{LineTerminator}				{ addEndToken(INTERNAL_IN_AS); return firstToken; }

	{AS_Identifier}					{ addToken(Token.IDENTIFIER); }

	{Whitespace}+					{ addToken(Token.WHITESPACE); }

	/* String/Character literals. */
	{AS_CharLiteral}					{ addToken(Token.LITERAL_CHAR); }
	{AS_UnclosedCharLiteral}			{ addToken(Token.ERROR_CHAR); addNullToken(); return firstToken; }
	{AS_ErrorCharLiteral}				{ addToken(Token.ERROR_CHAR); }
	{AS_StringLiteral}				{ addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); }
	{AS_UnclosedStringLiteral}			{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }
	{AS_ErrorStringLiteral}			{ addToken(Token.ERROR_STRING_DOUBLE); }

	/* Comment literals. */
	"/**/"						{ addToken(Token.COMMENT_MULTILINE); }
	{AS_MLCBegin}					{ start = zzMarkedPos-2; yybegin(AS_MLC); }
	{AS_LineCommentBegin}			{ start = zzMarkedPos-2; yybegin(AS_EOL_COMMENT); }

	/* Separators. */
	{AS_Separator}					{ addToken(Token.SEPARATOR); }
	{AS_Separator2}					{ addToken(Token.IDENTIFIER); }

	/* Operators. */
	{AS_Operator}					{ addToken(Token.OPERATOR); }

	/* Numbers */
	{AS_IntegerLiteral}				{ addToken(Token.LITERAL_NUMBER_DECIMAL_INT); }
	{AS_HexLiteral}					{ addToken(Token.LITERAL_NUMBER_HEXADECIMAL); }
	{AS_FloatLiteral}					{ addToken(Token.LITERAL_NUMBER_FLOAT); }
	{AS_ErrorNumberFormat}				{ addToken(Token.ERROR_NUMBER_FORMAT); }

	{AS_ErrorIdentifier}				{ addToken(Token.ERROR_IDENTIFIER); }

	/* Ended with a line not in a string or comment. */
	<<EOF>>						{ addEndToken(INTERNAL_IN_AS); return firstToken; }

	/* Catch any other (unhandled) characters and flag them as bad. */
	.							{ addToken(Token.ERROR_IDENTIFIER); }

}


<AS_MLC> {

	[^hwf\n\*]+				{}
	{URL}					{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); addHyperlinkToken(temp,zzMarkedPos-1, Token.COMMENT_MULTILINE); start = zzMarkedPos; }
	[hwf]					{}

	\n						{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); addEndToken(INTERNAL_IN_AS_MLC); return firstToken; }
	{AS_MLCEnd}				{ yybegin(AS); addToken(start,zzStartRead+1, Token.COMMENT_MULTILINE); }
	\*						{}
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); addEndToken(INTERNAL_IN_AS_MLC); return firstToken; }

}


<AS_EOL_COMMENT> {
	[^hwf\n]+				{}
	{URL}					{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_EOL); addHyperlinkToken(temp,zzMarkedPos-1, Token.COMMENT_EOL); start = zzMarkedPos; }
	[hwf]					{}
	\n						{ addToken(start,zzStartRead-1, Token.COMMENT_EOL); addEndToken(INTERNAL_IN_AS); return firstToken; }
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.COMMENT_EOL); addEndToken(INTERNAL_IN_AS); return firstToken; }

}
