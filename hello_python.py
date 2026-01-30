"""
简单的数字求和函数
"""

def sum_from_1_to_n(n):
    """
    使用for循环计算从1到n的和
    
    Args:
        n: 结束数字
        
    Returns:
        int: 1到n的总和
    """
    total = 0
    for i in range(1, n + 1):
        total += i
    return total


# 如果直接运行这个文件
if __name__ == "__main__":
    result = sum_from_1_to_n(10)
    print(f"从1加到10的结果是: {result}")


