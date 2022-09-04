package main

func processLogs(logsString []string, threshold int32) []string {

}

func reverse(nums []int32) {
    mid := len(nums) / 2
    for i := 0; i < mid; i++ {
        nums[i], nums[len(nums)-1-i] = nums[len(nums)-1-i], nums[i]
    }

}
