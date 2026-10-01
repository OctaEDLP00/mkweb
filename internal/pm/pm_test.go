package pm

import "testing"

func TestParseVersion(t *testing.T) {
	tests := []struct {
		name    string
		output  string
		want    string
		wantErr bool
	}{
		{"npm", "11.16.0\n", "11.16.0", false},
		{"pnpm", "12.6.0\n", "12.6.0", false},
		{"con v inicial", "v1.4.2\n", "1.4.2", false},
		{"con texto previo", "upm 0.3.1 (algo)\n", "0.3.1", false},
		{"prerelease", "1.0.0-beta.1\n", "1.0.0-beta.1", false},
		{"vacío", "", "", true},
		{"sin semver", "no instalado\n", "", true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := ParseVersion(tt.output)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("ParseVersion(%q) = %q, se esperaba error", tt.output, got)
				}
				return
			}
			if err != nil {
				t.Fatalf("ParseVersion(%q) devolvió error: %v", tt.output, err)
			}
			if got != tt.want {
				t.Errorf("ParseVersion(%q) = %q, se esperaba %q", tt.output, got, tt.want)
			}
		})
	}
}

func TestIsValid(t *testing.T) {
	for _, m := range Managers {
		if !IsValid(m) {
			t.Errorf("IsValid(%q) = false, se esperaba true", m)
		}
	}
	if IsValid("pip") {
		t.Error(`IsValid("pip") = true, se esperaba false`)
	}
}
