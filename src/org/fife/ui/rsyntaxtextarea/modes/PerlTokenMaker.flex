/*
 * 01/26/2008
 *
 * PerlTokenMaker.java - Scanner for Perl
 * 
 * This library is distributed under a modified BSD license.  See the included
 * RSyntaxTextArea.License.txt file for details.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * Scanner for Perl.<p>
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
 *   <li>The generated PerlTokenMaker.java</code> file will contain two
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
%class PerlTokenMaker
%extends AbstractJFlexCTokenMaker
%unicode
%type org.fife.ui.rsyntaxtextarea.Token


%{

	/**
	 * Token type specific to PerlTokenMaker; this signals that we are inside
	 * an unquoted/double quoted/backtick EOF heredoc.
	 */
	public static final int INTERNAL_HEREDOC_EOF_UNQUOTED			= -1;

	/**
	 * Token type specific to PerlTokenMaker; this signals that we are inside
	 * an single quoted EOF heredoc.
	 */
	public static final int INTERNAL_HEREDOC_EOF_SINGLE_QUOTED		= -2;

	/**
	 * Token type specific to PerlTokenMaker; this signals that we are inside
	 * an unquoted/double quoted/backtick EOT heredoc.
	 */
	public static final int INTERNAL_HEREDOC_EOT_UNQUOTED			= -3;

	/**
	 * Token type specific to PerlTokenMaker; this signals that we are inside
	 * an single quoted EOT heredoc.
	 */
	public static final int INTERNAL_HEREDOC_EOT_SINGLE_QUOTED		= -4;

	/**
	 * Token type specific to PerlTokenMaker; this signals we are in a POD
	 * block.
	 */
	public static final int INTERNAL_POD						= -5;

	/**
	 * Constructor.  This must be here because JFlex does not generate a
	 * no-parameter constructor.
	 */
	public PerlTokenMaker() {
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
	 */
	public void addToken(char[] array, int start, int end, int tokenType, int startOffset) {
		super.addToken(array, start,end, tokenType, startOffset);
		zzStartRead = zzMarkedPos;
	}


	/**
	 * Returns the text to place at the beginning and end of a
	 * line to "comment" it in a this programming language.
	 *
	 * @return The start and end strings to add to a line to "comment"
	 *         it out.
	 */
	public String[] getLineCommentStartAndEnd() {
		return new String[] { "#", null };
	}


	/**
	 * {@inheritDoc}
	 */
	public boolean getMarkOccurrencesOfTokenType(int type) {
		return super.getMarkOccurrencesOfTokenType(type) || type==Token.VARIABLE;
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
			case Token.LITERAL_STRING_DOUBLE_QUOTE:
				state = STRING;
				start = text.offset;
				break;
			case Token.LITERAL_CHAR:
				state = CHAR_LITERAL;
				start = text.offset;
				break;
			case Token.LITERAL_BACKQUOTE:
				state = BACKTICKS;
				start = text.offset;
				break;
			case INTERNAL_HEREDOC_EOF_UNQUOTED:
				state = HEREDOC_EOF_UNQUOTED;
				start = text.offset;
				break;
			case INTERNAL_HEREDOC_EOF_SINGLE_QUOTED:
				state = HEREDOC_EOF_SINGLE_QUOTED;
				start = text.offset;
				break;
			case INTERNAL_HEREDOC_EOT_UNQUOTED:
				state = HEREDOC_EOT_UNQUOTED;
				start = text.offset;
				break;
			case INTERNAL_HEREDOC_EOT_SINGLE_QUOTED:
				state = HEREDOC_EOT_SINGLE_QUOTED;
				start = text.offset;
				break;
			case INTERNAL_POD:
				state = POD;
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
	 * Returns whether a regular expression token can follow the specified
	 * token.
	 *
	 * @param t The token to check, which may be <code>null</code>.
	 * @return Whether a regular expression token may follow this one.
	 */
	private static final boolean regexCanFollow(Token t) {
		char ch;
		// We basically try to mimic Eclipse's JS editor's behavior here.
		return t==null ||
				//t.isOperator() ||
				(t.textCount==1 && (
					(ch=t.text[t.textOffset])=='=' ||
					ch=='(' ||
					ch==',' ||
					ch=='?' ||
					ch==':' ||
					ch=='[' ||
					ch=='!' ||
					ch=='&'
				)) ||
				/* Operators "==", "===", "!=", "!==", etc. */
				(t.type==Token.OPERATOR &&
					((ch=t.text[t.textOffset+t.textCount-1])=='=' || ch=='~'));
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

Letter							= [A-Za-z]
NonzeroDigit						= [1-9]
Digit							= ("0"|{NonzeroDigit})
HexDigit							= ({Digit}|[A-Fa-f])
OctalDigit						= ([0-7])
/*Escape							= ("\\"(([btnfr\"'\\])|([0123]{OctalDigit}?{OctalDigit}?)|({OctalDigit}{OctalDigit}?)))*/
NonSeparator						= ([^\t\f\r\n\ \(\)\{\}\[\]\;\,\.\=\>\<\!\~\?\:\+\-\*\/\&\|\^\%\"\'\`]|"#"|"\\")
IdentifierStart					= ({Letter}|"_")
IdentifierPart						= ({IdentifierStart}|{Digit})

LineTerminator				= (\n)
WhiteSpace				= ([ \t\f])

LineCommentBegin			= "#"

IntegerHelper1				= (({NonzeroDigit}{Digit}*)|"0")
IntegerHelper2				= ("0"(([xX]{HexDigit}+)|({OctalDigit}*)))
IntegerLiteral				= ({IntegerHelper1}[lL]?)
HexLiteral				= ({IntegerHelper2}[lL]?)
FloatHelper1				= ([fFdD]?)
FloatHelper2				= ([eE][+-]?{Digit}+{FloatHelper1})
FloatLiteral1				= ({Digit}+"."({FloatHelper1}|{FloatHelper2}|{Digit}+({FloatHelper1}|{FloatHelper2})))
FloatLiteral2				= ("."{Digit}+({FloatHelper1}|{FloatHelper2}))
FloatLiteral3				= ({Digit}+{FloatHelper2})
FloatLiteral				= ({FloatLiteral1}|{FloatLiteral2}|{FloatLiteral3}|({Digit}+[fFdD]))
ErrorNumberFormat			= (({IntegerLiteral}|{HexLiteral}|{FloatLiteral}){NonSeparator}+)

Separator					= ([\(\)\{\}\[\]])
Separator2				= ([\;:,.])

VariableStart				= ([\$\@\%)]"$"?)
BracedVariable				= ({VariableStart}\{{Identifier}\})
UnbracedVariable			= ({VariableStart}{Identifier})
BracedShellVariable			= ([\$]\{[\&\`\'\+\*\.\/\|\,\\\"\;\#\%\=\-\~\^\:\?\!\@\$\<\>\)\(\[\]\)\}])
UnbracedShellVariable		= ([\$][\&\`\'\+\*\.\/\|\,\\\"\;\#\%\=\-\~\^\:\?\!\@\$\<\>\)\(\[\]\)])
MatchVariable				= ([\$]{Digit})
Variable					= ({BracedVariable}|{UnbracedVariable}|{BracedShellVariable}|{UnbracedShellVariable}|{MatchVariable})
Regex						= ("/"([^\*\\/]|\\.)([^/\\]|\\.)*"/"[msixpogcadlu]*)

NonAssignmentOperator		= ("+"|"-"|"<="|"^"|"++"|"<"|"*"|">="|"%"|"--"|">"|"/"|"!="|"?"|">>"|"!"|"&"|"=="|":"|">>"|"~"|"|"|"&&"|">>>"|"->")
AssignmentOperator			= ("="|"-="|"*="|"/="|"|="|"&="|"^="|"+="|"%="|"<<="|">>="|">>>=")
BindingOperator				= ("=~"|"!~")
FunnyOperator				= (([\*][\'\"])|([\&][\'\"]))
Operator					= ({NonAssignmentOperator}|{AssignmentOperator}|{BindingOperator}|{FunnyOperator})

PodCommandsExceptCut		= ("="("pod"|"head1"|"head2"|"head3"|"head4"|"over"|"item"|"back"|"begin"|"end"|"for"|"encoding"))

Identifier				= ({IdentifierStart}{IdentifierPart}*)
ErrorIdentifier			= ({NonSeparator}+)


%state STRING
%state CHAR_LITERAL
%state BACKTICKS
%state HEREDOC_EOF_UNQUOTED
%state HEREDOC_EOF_SINGLE_QUOTED
%state HEREDOC_EOT_UNQUOTED
%state HEREDOC_EOT_SINGLE_QUOTED
%state POD

%%

<YYINITIAL> {

	/* Keywords */
	"and" |
	"cmp" |
	"continue" |
	"do" |
	"else" |
	"elsif" |
	"eq" |
	"esac" |
	"for" |
	"foreach" |
	"ge" |
	"if" |
	"last" |
	"le" |
	"ne" |
	"next" |
	"not" |
	"or" |
	"redo" |
	"sub" |
	"unless" |
	"until" |
	"while" |
	"xor"				{ addToken(Token.RESERVED_WORD); }

	/* Standard Functions */
	"abs" |
	"accept" |
	"alarm" |
	"atan2" |
	"bind" |
	"binmode" |
	"bless" |
	"caller" |
	"chdir" |
	"chmod" |
	"chomp" |
	"chop" |
	"chown" |
	"chr" |
	"chroot" |
	"close" |
	"closedir" |
	"connect" |
	"cos" |
	"crypt" |
	"dbmclose" |
	"dbmopen" |
	"defined" |
	"delete" |
	"die" |
	"dump" |
	"each" |
	"endgrent" |
	"endhostent" |
	"endnetent" |
	"endprotoent" |
	"endpwent" |
	"endservent" |
	"eof" |
	"eval" |
	"exec" |
	"exists" |
	"exit" |
	"exp" |
	"fcntl" |
	"fileno" |
	"flock" |
	"fork" |
	"formline" |
	"getc" |
	"getgrent" |
	"getgrgid" |
	"getgrnam" |
	"gethostbyaddr" |
	"gethostbyname" |
	"gethostent" |
	"getlogin" |
	"getnetbyaddr" |
	"getnetbyname" |
	"getnetent" |
	"getpeername" |
	"getpgrp" |
	"getppid" |
	"getpriority" |
	"getprotobyname" |
	"getprotobynumber" |
	"getprotoent" |
	"getpwent" |
	"getpwnam" |
	"getpwuid" |
	"getservbyname" |
	"getservbyport" |
	"getservent" |
	"getsockname" |
	"getsockopt" |
	"glob" |
	"gmtime" |
	"goto" |
	"grep" |
	"hex" |
	"index" |
	"int" |
	"ioctl" |
	"join" |
	"keys" |
	"kill" |
	"last" |
	"lc" |
	"lcfirst" |
	"length" |
	"link" |
	"listen" |
	"local" |
	"localtime" |
	"log" |
	"lstat" |
	"map" |
	"mkdir" |
	"msgctl" |
	"msgget" |
	"msgrcv" |
	"msgsnd" |
	"my" |
	"next" |
	"no" |
	"oct" |
	"open" |
	"opendir" |
	"ord" |
	"our" |
	"pack" |
	"package" |
	"pipe" |
	"pop" |
	"pos" |
	"print" |
	"printf" |
	"prototype" |
	"push" |
	"quotemeta" |
	"rand" |
	"read" |
	"readdir" |
	"readline" |
	"readlink" |
	"readpipe" |
	"recv" |
	"redo" |
	"ref" |
	"rename" |
	"require" |
	"reset" |
	"return" |
	"reverse" |
	"rewinddir" |
	"rindex" |
	"rmdir" |
	"scalar" |
	"seek" |
	"seekdir" |
	"select" |
	"semctl" |
	"semget" |
	"semop" |
	"send" |
	"sethostent" |
	"setgrent" |
	"setnetent" |
	"setpgrp" |
	"setpriority" |
	"setprotoent" |
	"setpwent" |
	"setservent" |
	"setsockopt" |
	"shift" |
	"shmctl" |
	"shmget" |
	"shmread" |
	"shmwrite" |
	"shutdown" |
	"sin" |
	"sleep" |
	"socket" |
	"socketpair" |
	"sort" |
	"splice" |
	"split" |
	"sprintf" |
	"sqrt" |
	"srand" |
	"stat" |
	"study" |
	"sub" |
	"substr" |
	"symlink" |
	"syscall" |
	"sysopen" |
	"sysread" |
	"sysseek" |
	"system" |
	"syswrite" |
	"tell" |
	"telldir" |
	"tie" |
	"tied" |
	"time" |
	"times" |
	"truncate" |
	"uc" |
	"ucfirst" |
	"umask" |
	"undef" |
	"unlink" |
	"unpack" |
	"unshift" |
	"untie" |
	"use" |
	"utime" |
	"values" |
	"vec" |
	"wait" |
	"waitpid" |
	"wantarray" |
	"warn" |
	"write"			{ addToken(Token.FUNCTION); }

}

<YYINITIAL> {

	{LineTerminator}				{ addNullToken(); return firstToken; }
	{Identifier}					{ addToken(Token.IDENTIFIER); }
	{WhiteSpace}+					{ addToken(Token.WHITESPACE); }
	{Variable}					{ addToken(Token.VARIABLE); }

	/* String/Character literals. */
	\"							{ start = zzMarkedPos-1; yybegin(STRING); }
	\'							{ start = zzMarkedPos-1; yybegin(CHAR_LITERAL); }
	\`							{ start = zzMarkedPos-1; yybegin(BACKTICKS); }

	/* Comment literals. */
	{LineCommentBegin}"!".*			{ addToken(Token.PREPROCESSOR); addNullToken(); return firstToken; }
	{LineCommentBegin}.*			{ addToken(Token.COMMENT_EOL); addNullToken(); return firstToken; }

	/* Easily identifiable regexes of the form "/.../". This is not foolproof. */
	{Regex}		{
					boolean highlightedAsRegex = false;
					if (firstToken==null) {
						addToken(Token.REGEX);
						highlightedAsRegex = true;
					}
					else {
						// If this is *likely* to be a regex, based on
						// the previous token, highlight it as such.
						Token t = firstToken.getLastNonCommentNonWhitespaceToken();
						if (regexCanFollow(t)) {
							addToken(Token.REGEX);
							highlightedAsRegex = true;
						}
					}
					// If it doesn't *appear* to be a regex, highlight it as
					// individual tokens.
					if (!highlightedAsRegex) {
						int temp = zzStartRead + 1;
						addToken(zzStartRead, zzStartRead, Token.OPERATOR);
						zzStartRead = zzCurrentPos = zzMarkedPos = temp;
					}
				}

	/* More regexes (m/.../, s!...!!, etc.).  This is nowhere near */
	/* exhaustive, but is rather just the common ones.             */
	m"/"[^/]*"/"[msixpodualgc]*				{ addToken(Token.REGEX); }
	m"!"[^!]*"!"[msixpodualgc]*				{ addToken(Token.REGEX); }
	m"|"[^\|]*"|"[msixpodualgc]*			{ addToken(Token.REGEX); }
	m\\[^\\]*\\[msixpodualgc]*				{ addToken(Token.REGEX); }
	s"/"[^/]*"/"[^/]*"/"[msixpodualgcer]*	{ addToken(Token.REGEX); }
	s"!"[^!]*"!"[^!]*"!"[msixpodualgcer]*	{ addToken(Token.REGEX); }
	s"|"[^\|]*"|"[^\|]*"|"[msixpodualgcer]*	{ addToken(Token.REGEX); }
	(tr|y)"/"[^/]*"/"[^/]*"/"[cdsr]*		{ addToken(Token.REGEX); }
	(tr|y)"!"[^!]*"!"[^!]*"!"[cdsr]*		{ addToken(Token.REGEX); }
	(tr|y)"|"[^\|]*"|"[^\|]*"|"[cdsr]*		{ addToken(Token.REGEX); }
	(tr|y)\\[^\\]*\\[^\\]*\\[cdsr]*		{ addToken(Token.REGEX); }
	qr"/"[^/]*"/"[msixpodual]*			{ addToken(Token.REGEX); }
	qr"!"[^/]*"!"[msixpodual]*			{ addToken(Token.REGEX); }
	qr"|"[^/]*"|"[msixpodual]*			{ addToken(Token.REGEX); }
	qr\\[^/]*\\[msixpodual]*			{ addToken(Token.REGEX); }

	/* "Here-document" syntax.  This is only implemented for the common */
	/* cases.                                                           */
	"<<EOF"						{ start = zzStartRead; yybegin(HEREDOC_EOF_UNQUOTED); }
	"<<" {WhiteSpace}* \""EOF"\"		{ start = zzStartRead; yybegin(HEREDOC_EOF_UNQUOTED); }
	"<<" {WhiteSpace}* \'"EOF"\'		{ start = zzStartRead; yybegin(HEREDOC_EOF_SINGLE_QUOTED); }
	"<<" {WhiteSpace}* \`"EOF"\`		{ start = zzStartRead; yybegin(HEREDOC_EOF_UNQUOTED); }
	"<<EOT"						{ start = zzStartRead; yybegin(HEREDOC_EOT_UNQUOTED); }
	"<<" {WhiteSpace}* \""EOT"\"		{ start = zzStartRead; yybegin(HEREDOC_EOT_UNQUOTED); }
	"<<" {WhiteSpace}* \'"EOT"\'		{ start = zzStartRead; yybegin(HEREDOC_EOT_SINGLE_QUOTED); }
	"<<" {WhiteSpace}* \`"EOT"\`		{ start = zzStartRead; yybegin(HEREDOC_EOT_UNQUOTED); }

	/* POD commands. */
	{PodCommandsExceptCut}			{ addToken(Token.COMMENT_EOL); start = zzMarkedPos; yybegin(POD); }

	/* Separators and operators. */
	{Separator}					{ addToken(Token.SEPARATOR); }
	{Separator2}					{ addToken(Token.IDENTIFIER); }
	{Operator}					{ addToken(Token.OPERATOR); }

	/* Numbers */
	{IntegerLiteral}				{ addToken(Token.LITERAL_NUMBER_DECIMAL_INT); }
	{HexLiteral}					{ addToken(Token.LITERAL_NUMBER_HEXADECIMAL); }
	{FloatLiteral}					{ addToken(Token.LITERAL_NUMBER_FLOAT); }
	{ErrorNumberFormat}				{ addToken(Token.ERROR_NUMBER_FORMAT); }

	{ErrorIdentifier}				{ addToken(Token.ERROR_IDENTIFIER); }

	/* Ended with a line not in a string or comment. */
	<<EOF>>						{ addNullToken(); return firstToken; }

	/* Catch any other (unhandled) characters and flag them as bad. */
	.							{ addToken(Token.ERROR_IDENTIFIER); }

}


<STRING> {
	[^\n\\\$\@\%\"]+		{}
	\n					{ addToken(start,zzStartRead-1, Token.LITERAL_STRING_DOUBLE_QUOTE); return firstToken; }
	\\.?					{ /* Skip escaped chars. */ }
	{Variable}			{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.LITERAL_STRING_DOUBLE_QUOTE); addToken(temp,zzMarkedPos-1, Token.VARIABLE); start = zzMarkedPos; }
	{VariableStart}		{}
	\"					{ yybegin(YYINITIAL); addToken(start,zzStartRead, Token.LITERAL_STRING_DOUBLE_QUOTE); }
	<<EOF>>				{ addToken(start,zzStartRead-1, Token.LITERAL_STRING_DOUBLE_QUOTE); return firstToken; }
}


<CHAR_LITERAL> {
	[^\n\\\']+			{}
	\\.?					{ /* Skip escaped single quotes only, but this should still work. */ }
	\n					{ addToken(start,zzStartRead-1, Token.LITERAL_CHAR); return firstToken; }
	\'					{ yybegin(YYINITIAL); addToken(start,zzStartRead, Token.LITERAL_CHAR); }
	<<EOF>>				{ addToken(start,zzStartRead-1, Token.LITERAL_CHAR); return firstToken; }
}


<BACKTICKS> {
	[^\n\\\$\@\%\`]+		{}
	\n					{ addToken(start,zzStartRead-1, Token.LITERAL_BACKQUOTE); return firstToken; }
	\\.?					{ /* Skip escaped chars. */ }
	{Variable}			{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.LITERAL_BACKQUOTE); addToken(temp,zzMarkedPos-1, Token.VARIABLE); start = zzMarkedPos; }
	{VariableStart}		{}
	\`					{ yybegin(YYINITIAL); addToken(start,zzStartRead, Token.LITERAL_BACKQUOTE); }
	<<EOF>>				{ addToken(start,zzStartRead-1, Token.LITERAL_BACKQUOTE); return firstToken; }
}


<HEREDOC_EOF_UNQUOTED> {
	/* NOTE: The closing "EOF" is supposed to be on a line by itself -  */
	/* no surrounding whitespace or other chars.  However, the way      */
	/* we're hacking the JFLex scanning, something like ^"EOF"$ doesn't */
	/* work.  Fortunately we don't need the start- and end-line anchors */
	/* since the production after "EOF" will match any line containing  */
	/* EOF and any other chars.                                         */
	/* NOTE2: This case is used for unquoted <<EOF, double quoted       */
	/* <<"EOF" and backticks <<`EOF`, since they all follow the same    */
	/* syntactic rules.                                                 */
	"EOF"				{ if (start==zzStartRead) { addToken(Token.PREPROCESSOR); addNullToken(); return firstToken; } }
	[^\n\\\$\@\%]+			{}
	\n					{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_HEREDOC_EOF_UNQUOTED); return firstToken; }
	\\.?					{ /* Skip escaped chars. */ }
	{Variable}			{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.PREPROCESSOR); addToken(temp,zzMarkedPos-1, Token.VARIABLE); start = zzMarkedPos; }
	{VariableStart}		{}
	<<EOF>>				{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_HEREDOC_EOF_UNQUOTED); return firstToken; }
}


<HEREDOC_EOF_SINGLE_QUOTED> {
	/* NOTE: The closing "EOF" is supposed to be on a line by itself -  */
	/* no surrounding whitespace or other chars.  However, the way      */
	/* we're hacking the JFLex scanning, something like ^"EOF"$ doesn't */
	/* work.  Fortunately we don't need the start- and end-line anchors */
	/* since the production after "EOF" will match any line containing  */
	/* EOF and any other chars.                                         */
	"EOF"				{ if (start==zzStartRead) { addToken(Token.PREPROCESSOR); addNullToken(); return firstToken; } }
	[^\n\\]+				{}
	\n					{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_HEREDOC_EOF_SINGLE_QUOTED); return firstToken; }
	\\.?					{ /* Skip escaped chars. */ }
	<<EOF>>				{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_HEREDOC_EOF_SINGLE_QUOTED); return firstToken; }
}


<HEREDOC_EOT_UNQUOTED> {
	/* NOTE: The closing "EOT" is supposed to be on a line by itself -  */
	/* no surrounding whitespace or other chars.  However, the way      */
	/* we're hacking the JFLex scanning, something like ^"EOT"$ doesn't */
	/* work.  Fortunately we don't need the start- and end-line anchors */
	/* since the production after "EOT" will match any line containing  */
	/* EOF and any other chars.                                         */
	/* NOTE2: This case is used for unquoted <<EOT, double quoted       */
	/* <<"EOT" and backticks <<`EOT`, since they all follow the same    */
	/* syntactic rules.                                                 */
	"EOT"				{ if (start==zzStartRead) { addToken(Token.PREPROCESSOR); addNullToken(); return firstToken; } }
	[^\n\\\$\@\%]+			{}
	\n					{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_HEREDOC_EOT_UNQUOTED); return firstToken; }
	\\.?					{ /* Skip escaped chars. */ }
	{Variable}			{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.PREPROCESSOR); addToken(temp,zzMarkedPos-1, Token.VARIABLE); start = zzMarkedPos; }
	{VariableStart}		{}
	<<EOF>>				{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_HEREDOC_EOT_UNQUOTED); return firstToken; }
}


<HEREDOC_EOT_SINGLE_QUOTED> {
	/* NOTE: The closing "EOT" is supposed to be on a line by itself -  */
	/* no surrounding whitespace or other chars.  However, the way      */
	/* we're hacking the JFLex scanning, something like ^"EOT"$ doesn't */
	/* work.  Fortunately we don't need the start- and end-line anchors */
	/* since the production after "EOT" will match any line containing  */
	/* EOT and any other chars.                                         */
	"EOT"				{ if (start==zzStartRead) { addToken(Token.PREPROCESSOR); addNullToken(); return firstToken; } }
	[^\n\\]+				{}
	\n					{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_HEREDOC_EOT_SINGLE_QUOTED); return firstToken; }
	\\.?					{ /* Skip escaped chars. */ }
	<<EOF>>				{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_HEREDOC_EOT_SINGLE_QUOTED); return firstToken; }
}


<POD> {
	[^\n\=]+				{}
	"=cut"				{ if (start==zzStartRead) { addToken(Token.COMMENT_DOCUMENTATION); yybegin(YYINITIAL); } }
	{PodCommandsExceptCut}	{ if (start==zzStartRead) { int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_DOCUMENTATION); addToken(temp,zzMarkedPos-1, Token.COMMENT_EOL); start = zzMarkedPos; } }
	=					{}
	\n |
	<<EOF>>				{ addToken(start,zzStartRead-1, Token.COMMENT_DOCUMENTATION); addEndToken(INTERNAL_POD); return firstToken; }
}

