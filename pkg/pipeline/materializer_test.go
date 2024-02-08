package pipeline

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMaterializer_Render(t *testing.T) {
	t.Parallel()

	materializer := Materializer{
		MaterializationMap: make(map[MaterializationType]map[MaterializationStrategy]MaterializerFunc),
	}

	asset := &Asset{
		Materialization: Materialization{
			Type: MaterializationTypeNone,
		},
	}

	query := "SELECT * FROM table"
	expected := "SELECT * FROM table"

	result, err := materializer.Render(asset, query)
	require.NoError(t, err)
	assert.Equal(t, expected, result)
}
