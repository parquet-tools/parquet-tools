package cmd

import (
	"fmt"
)

// RowCountCmd is a kong command for rowcount
type RowCountCmd struct {
	CommonOption
	Detailed bool `help:"Detailed rowcount."`
}

// Run does actual rowcount job
func (c *RowCountCmd) Run(ctx *Context) error {
	reader, err := newParquetFileReader(c.URI)
	if err != nil {
		return err
	}
	fmt.Println(reader.GetNumRows())
	return nil
}
