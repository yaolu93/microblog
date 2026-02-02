class Solution:
    def validPalindrome(self, s: str) -> bool:

        left = 0
        right = len(s) - 1

        while left < right:
            if s[left] == s[right]:
                left += 1
                right -= 1

            else:
                return (self.isPalindrome(s, left + 1, right) or self.isPalindrome(s, left, right - 1))

        return True
                

    
    def isPalindrome(self, s: str, left: int, right: int) -> bool:
        while left < right:

            if s[left] != s[right]:
                return False

            left += 1
            right -= 1
        return True



# ... 你的 Solution 类代码保持不变 ...
if __name__ == "__main__":
    s = Solution()
    assert s.validPalindrome("aba") == True
    assert s.validPalindrome("abca") == True
    assert s.validPalindrome("abc") == False
    print("OK.")
