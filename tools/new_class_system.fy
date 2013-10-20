# c = Fancy Compiler compile_code: "A, B = 0, 1" vars: nil file: "()" line: 0
# Rubinius InstructionDecoder new(c iseq) show()
# ast = Fancy Parser parse_code: "A B c = 0" file: "()" line: 0

ast = Fancy Parser parse_code: "{ nil }" file: "()" line: 0
exprlist = ast.body

constant = Fancy Parser parse_code: "A" file: "()" line: 0 . body . expressions[0]

class ClassDefTwo : Fancy AST Node {
  def initialize: @line name: @name parent: @parent body: @body {
    unless: @body do: {
      @body = Fancy AST ExpressionList new(@line)
    }
    @body = Fancy AST BlockLiteral new: @line args: (Fancy AST BlockArgs new: @line) body: @body partial: false
    if: (@name kind_of?(Fancy::AST::Identifier)) then: {
      @name = @name name
    }
    #if: (@parent nil?) then: {
    #  @parent = Fancy AST ToplevelConstant new: @line string: "::Class"
    #  # g meta_send_call(g find_literal('call), 1) # Faster calling for blocks (g send('call, 1))
    #}
    # "ClassDefTwo: ("+(name inspect)+", "+(parent inspect)+", "+(body inspect)+")" println
  }
  def bytecode: g {
    pos(g)
    
    if: @parent then: {
      @parent bytecode: g
    } else: {
      g push_cpath_top()
      g find_const('Object)
    }
    g send('subclass, 0)
    # Keep a copy around, since we're about to overwrite the top with a send.
    g dup()
    # Subclass created and now sitting on the stack. So create the block and
    # class_eval it in the subclass.
    g push_state(Rubinius AST ClosedScope.new(@line))
    g add_scope()
    @body bytecode: g
    g pop_state()
    
    # Stack now has just the new class object
    g push_literal(@name) # S: class, name
    g push_scope()        # S: class, name, scope
    g rotate(3)           # S: scope, name, class
    g send('const_set_fast, 2)
    g pop()
    
  }
}

c = ClassDefTwo new: 0 name: constant parent: nil body: exprlist
# # c inspect println
# class Test {
#   dynamic_method(':test) |g| {
#     C bytecode: g
#     g ret()
#   }
# }
# t = Test new
# t test
# # (Test method: 'test) inspect println
# # (t call: 'A) println
# t instance_eval() |e| {
#   A println
# }

g = Rubinius ToolSet Runtime Generator new()
g name=('test)
g file=('test)
g set_line(Integer(0))

c bytecode: g

g close()
g use_detected()
g encode()

code = g package(Rubinius CompiledCode)
script = code create_script()
# code scope=(Rubinius ConstantScope new(B, Rubinius ConstantScope new(Object)))

# code eval_source() inspect println
script eval_source() inspect println

