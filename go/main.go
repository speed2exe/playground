package main

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"os"
	"strings"
	"unicode"
)

func main() {
	buffer := bytes.Buffer{}
	csvWriter := csv.NewWriter(&buffer)

	// write header
	header := make([]string, 0)
	header = append(header, "time")
	header = append(header, "blockNumber")
	csvWriter.Write(header)

	csvWriter.Flush()
	fmt.Println(buffer.String())

	os.WriteFile("test.csv", buffer.Bytes(), 0644)
}

func strongPasswordCheckerII(s string) bool {
	if len(s) < 8 {
		return false
	}

	var hasLower, hasUpper, hasDigit, hasSpecial, has8Chars, hasConsecutive bool
	prev := rune(0)

	for _, char := range s {
		if char == prev {
			return false
		}
		prev = char

		if unicode.IsLetter(char) {
			if unicode.IsLower(char) {
				hasLower = true
			} else {
				hasUpper = true
			}
			continue
		}

		if unicode.IsDigit(char) {
			hasDigit = true
			continue
		}

		if strings.Contains("!@#$%^&*()-+", string(char)) {
			hasSpecial = true
		}
	}

	// logic to check for 8 chars, consecutive chars, etc
	fmt.Println(hasLower, hasUpper, hasDigit, hasSpecial, has8Chars, hasConsecutive)

	return hasLower && hasUpper && hasDigit && hasSpecial && has8Chars && !hasConsecutive
}
