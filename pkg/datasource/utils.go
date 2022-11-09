package datasource

import (
	"fmt"
	"math"
)

// generateColumnsLabels generates a list containing the string representations of the numbers from 0 to n-1, with the right number of leading 0s.
// e.g., for n=16 -> ["00", "01, ..., "15"], for n=106 -> ["000", "001", ..., "115"]
func generateColumnsLabels(n int) []string {

	labels := make([]string, n)
	figures := int(math.Ceil(math.Log10(float64(n))))

	for i := 0; i < n; i++ {
		labels[i] = fmt.Sprintf(fmt.Sprintf("%%0%dd", figures), i)
	}

	return labels
}
