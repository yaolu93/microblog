"""
测试sum_numbers.py中的函数
"""

import pytest
from hello_python import sum_from_1_to_n


class TestSumNumbers:
    """测试求和函数"""
    
    def test_sum_1_to_10(self):
        """测试从1加到10"""
        assert sum_from_1_to_n(10) == 55
    
    def test_sum_1_to_1(self):
        """测试边界情况：只有一个数字"""
        assert sum_from_1_to_n(1) == 1
    
    def test_sum_1_to_5(self):
        """测试从1加到5"""
        assert sum_from_1_to_n(5) == 15
    
    def test_sum_1_to_100(self):
        """测试更大的数字"""
        assert sum_from_1_to_n(100) == 5050
    
    def test_sum_zero(self):
        """测试0的情况"""
        assert sum_from_1_to_n(0) == 0
    
    def test_negative_number(self):
        """测试负数情况"""
        assert sum_from_1_to_n(-5) == 0


# 可以单独运行某个测试
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
