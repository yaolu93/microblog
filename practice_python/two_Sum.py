def two_sum(nums, target):

    hashmap = {}

    for i in range(len(nums)):
        num = nums[i]  # value/ key
        complement = target - num

        if complement in hashmap:  # this is comparing the key
            return [hashmap[complement], i]

        hashmap[num] = i

    return []


if __name__ == "__main__":

    nums = [2, 7, 11, 13]
    target = 9
    print(f"{two_sum(nums, target)=}")
