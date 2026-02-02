a = [1,2,3,4,4,5,1,2,3,4,4,5,5,6,7,8,9,9]
b = [2,1,2,3,4,1,2,3,4,1,4,2,2,1,4,5,6,7,8,9,9]

combined = a + b
result = []

for x in combined:
    if x not in result:
        result.append(x)

result.sort()

print(f"result = {result}")
