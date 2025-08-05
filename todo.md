- [ ] add Lexer::expect_char
- [ ] add Lexer::peek_is_char
- [ ] add Char::is_bmp // basic multilingual plane
- [ ] check if Lexer needs keep track of line and column
      design choice leave the main loop to track line number
      the rationale is that it is expensive to track line 
      every time we advance the position