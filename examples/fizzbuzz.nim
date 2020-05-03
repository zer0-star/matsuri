import matsuri

for i in 1 .. 30:
  match (i mod 3, i mod 5):
  of (0, 0):
    echo "FizzBuzz"
  of (0, _):
    echo "Fizz"
  of (_, 0):
    echo "Buzz"
  of (_, _):
    echo i
