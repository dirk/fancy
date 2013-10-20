class Fancy AST {
  class ClassDef : Rubinius AST Class {
    def initialize: @line name: @name parent: @parent body: @body (ExpressionList new: @line) {
      { @body = ExpressionList new: @line } unless: @body
      @original_body = @body
      @original_name = @name
      
      name = nil
      
      if: (@name is_a?: NestedConstant) then: {
        name = @name scoped
      } else: {
        name = @name string to_sym()
      }

      if: (@body empty?) then: {
        @body unshift_expression: $ NilLiteral new: @line
      }

      initialize(@line, name, @parent, @body)
      # @body will be a Rubinius::AST::ClassScope now.
    }

    def bytecode: g {
      pos(g)
      docstring = body() body() docstring
      if: docstring then: {
        setdoc = MessageSend new: @line \
                             message: (Identifier from: "for:append:" line: @line) \
                             to: (Identifier from: "Fancy::Documentation" line: @line) \
                             args: (MessageArgs new: @line args: [Self new: @line, docstring])
      
        # Replace first string expression to set documentation.
        body() body() unshift_expression: setdoc
      }
      bytecode(g)
      return nil
      
      oname   = @original_name
      name    = @name name() to_sym
      defined = g new_label()
      name_error_exc = g new_label()
      end = g new_label()
      
      classname = nil
      if: (oname is_a?: NestedConstant) then: {
        parts = oname name to_s split: "::" . map: |p| { p to_sym }
        classname = parts last
      } else: {
        classname = oname name to_sym
      }
      
      if: @parent then: {
        @parent bytecode: g
      } else: {
        g setup_unwind(name_error_exc, Rubinius AST EnsureType)
        
        # Try to resolve the name
        @name bytecode(g)
        g check_interrupts()
        
        # If found it doesn't raise an exception.
        g pop_unwind()
        g goto(defined)
        
        # Otherwise it'll raise a NameError...
        name_error_exc set!()
        g clear_exception()
        # In which case we'll just use a top level object.
        g push_cpath_top()
        g find_const('Object)
      }
      
      # Stack: superclass
      block = BlockLiteral new: @line args: (BlockArgs new: []) body: @original_body partial: false
      
      g push_literal(classname)         # S: superclass, classname
      self resolve_scope: oname with: g # S: superclass, classname, scope
      block bytecode: g                 # S: superclass, classname, scope, block
      g send_stack_with_block(g find_literal('subclass), 2)
      
      # Subclass created and now sitting on the stack.
      #self print: ("undef (name: "+(name to_s)+"): ") with: g
      #self inspect_top: g
      
      g dup() # Copy for us to work with.
        # Stack now has just the new class object
        # S: class
        self resolve_name_and_scope: oname with: g
        # S: class, name, scope
        g rotate(3)           # S: scope, name, class
        g send('const_set, 2) # S: (somethin')
      g pop() # Toss away copy (whatever it is after const_set)
      g goto(end) # Return
      
      
      defined set!()
      # Class was already defined.
      #self print: ("def (name: "+(name to_s)+"): ") with: g
      #self inspect_top: g
      # The @body set by super-initializing with Rubinius::AST::ClassScope
      # will work perfectly now.
      @body bytecode(g)
      end set!()
    }
    
    # Stack:
    #   Before: ...
    #   After:  ..., scope
    def resolve_scope: fname with: g {
      exits = 0
      if: (fname is_a?: NestedConstant) then: {
        # Resolving ensted constants.
        parts = fname name to_s split: "::"
        lead = parts[[0, (parts length . - 2)]] # Trim off the last one
        lead each: |p| {
          # find_const is in-place so we'll use that to make sure there's
          # always just one scope on the stack.
          if: (exits > 0) then: {
            g find_const(p to_sym)
          } else: {
            g push_const(p to_sym)
            exits = exits + 1
          }
        }#lead each
      } else: {
        g push_scope()
      }
    }
    
    # Stack:
    #   Before: ...
    #   After:  ..., name, scope
    def resolve_name_and_scope: fname with: g {
      exits = 0
      if: (fname is_a?: NestedConstant) then: {
        # Resolving ensted constants.
        parts = fname name to_s split: "::"
        
        g push_literal(parts last . to_sym) # S: name
        
        lead = parts[[0, (parts length . - 2)]] # Trim off the last one
        lead each: |p| {
          # find_const is in-place so we'll use that to make sure there's
          # always just one scope on the stack.
          if: (exits > 0) then: {
            g find_const(p to_sym)
          } else: {
            g push_const(p to_sym)
            exits = exits + 1
          }
        }
        # S: name, scope
      } else: {
        g push_literal(fname name to_sym) # S: name
        g push_scope()       # S: name, scope
      }
    }
    
    def print: string with: g {
      g push_cpath_top()     # S: cpath
      g find_const('Kernel)  # S: kernel
      g push_literal(string) # S: kernel, string
      g send('print, 1)      # S: _
      g pop()
    }
    def inspect_top: g {
      g dup()
      g push_cpath_top()    # S: x, cpath
      g find_const('Kernel) # S: x, kernel
      g swap()              # S: kernel, x
      g send('inspect, 0)   # S: kernel, x-i
      g send('puts, 1)      # S: _
      g pop()
    }
    
    
  }
}
