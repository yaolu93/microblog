motor = ["Honda", "yamaha", "suzuki"]

first_motor = motor[0]
print(f"first_motor = {first_motor}")

pop_motor = motor.pop(1)
print(f"pop_motor = {pop_motor}")

print(f"motor = {motor}")

motor.append("ducati")
print(f"motor = {motor}")

motor.insert(0, "bmw")
print(f"motor = {motor}")

motor.insert(2, "kawasaki")
print(f"motor = {motor}")

motor.remove("Honda")
print(f"motor = {motor}")

motor.pop(2)
print(f"motor = {motor}")

# motor.reverse()
# print(f"motor = {motor}")


motor.sort()
print(f"motor = {motor}")


sorted(motor)
print(f"motor = {motor}")

print(motor[-2])
