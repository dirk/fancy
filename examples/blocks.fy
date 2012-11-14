# blocks.fy
# Examples of fancy code blocks

x = { "Println from within block!" println }
x call # calls x and prints: "Println from within block!"

y = |x y| { x + y println }
y call: [2, 3] # calls y and prints: 5

# prints numbers 0 to 20
num = 0
while: { num <= 20 } do: {
  num println
  num = num + 1
}
