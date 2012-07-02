# Taken from https://github.com/oxos/gmail-oauth-thread-stats/blob/master/gmail_imap_extensions_compatibility.rb

module Net
  class IMAP
    class ResponseParser

      def msg_att
        match(T_LPAR)
        attr = { }
        while true
          token = lookahead
          case token.symbol
          when T_RPAR
            shift_token
            break
          when T_SPACE
            shift_token
            next
          end
          case token.value
          when /\A(?:ENVELOPE)\z/ni
            name, val = envelope_data
          when /\A(?:FLAGS)\z/ni
            name, val = flags_data
          when /\A(?:INTERNALDATE)\z/ni
            name, val = internaldate_data
          when /\A(?:RFC822(?:\.HEADER|\.TEXT)?)\z/ni
            name, val = rfc822_text
          when /\A(?:RFC822\.SIZE)\z/ni
            name, val = rfc822_size
          when /\A(?:BODY(?:STRUCTURE)?)\z/ni
            name, val = body_data
          when /\A(?:UID)\z/ni
            name, val = uid_data

            # Gmail extension additions.
            # Cargo-Cult code warning: # I have no idea why the regexp - just copying a pattern
          when /\A(?:X-GM-LABELS)\z/ni
            name, val = labels_data
          when /\A(?:X-GM-MSGID)\z/ni
            name, val = uid_data
          when /\A(?:X-GM-THRID)\z/ni
            name, val = uid_data
          else
            parse_error("unknown attribute `%s'", token.value)
          end
          attr[name] = val
        end
        return attr
      end

      def labels_data
        token = match(T_ATOM)
        name = token.value.upcase
        match(T_SPACE)
        return name, label_list
      end

      EXPR_LABELS = :EXPR_LABELS
      T_GM_LABEL = :GM_LABEL

      def label_list
        @lex_state = EXPR_LABELS
        match(T_LPAR)
        labels = []
        while true
          token = lookahead
          case token.symbol
          when T_RPAR
            shift_token
            break
          when T_SPACE
            shift_token
            next
          end
          shift_token
          labels << token.value
        end
        @lex_state = EXPR_BEG
        return labels
      end

      LABELS_REGEXP = /\G(?:\
(?# 1:  SPACE     )( )|\
(?# 2:  GM_LABEL  )"\\([^\x80-\xff(){ \x00-\x1f\x7f%"\\]+)"|\
(?# 3:  GM_LABEL2 )"\\\\([^\x80-\xff(){ \x00-\x1f\x7f%"\\]+)"|\
(?# 4:  FLAG      )\\([^\x80-\xff(){ \x00-\x1f\x7f%"\\]+)|\
(?# 5:  QUOTED    )"((?:[^\x00\r\n"\\]|\\["\\])*)"|\
(?# 6:  ATOM      )([^\x80-\xff(){ \x00-\x1f\x7f%*"\\]+)|\
(?# 7:  LPAR      )(\()|\
(?# 8:  RPAR      )(\)))/ni

      alias_method :orig_next_token, :next_token
      def next_token
        case @lex_state
        when EXPR_LABELS
          if @str.index(LABELS_REGEXP, @pos)
            @pos = $~.end(0)
            if $1
              return Token.new(T_SPACE, $+)
            elsif $2 || $3 || $4
              symbol = $+.capitalize.untaint.intern
              return Token.new(T_GM_LABEL, symbol)
            elsif $5
              return Token.new(T_QUOTED, $+.gsub(/\\(["\\])/n, "\\1"))
            elsif $6
              return Token.new(T_ATOM, $+)
            elsif $7
              return Token.new(T_LPAR, $+)
            elsif $8
              return Token.new(T_RPAR, $+)
            else
              parse_error("[Net::IMAP BUG] LABEL_REGEXP is invalid")
            end
          else
            @str.index(/\S*/n, @pos)
            parse_error("unknown token - %s", $&.dump)
          end
        else
          orig_next_token
        end
      end
    end
  end

end