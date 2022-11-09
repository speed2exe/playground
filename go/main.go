package main

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"os"
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
