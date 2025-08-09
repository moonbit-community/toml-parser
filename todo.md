- [x] add Lexer::expect_char ✅ **Completed**
- [x] check if Lexer needs keep track of line and column ✅ **Completed**
      design choice leave the main loop to track line number
      the rationale is that it is expensive to track line 
      every time we advance the position
      
**Array of Tables Support - COMPLETED ✅**
- [x] Added array of tables syntax `[[section]]` support
- [x] Parser can now distinguish between `[table]` and `[[array]]` 
- [x] Full nested path support for array of tables
- [x] Tests added for basic and nested array of tables
- [x] Documentation updated to reflect new capabilities