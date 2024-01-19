package bn254

import (
	"bytes"
	"encoding/binary"
	"errors"
	"io"

	ecc "github.com/consensys/gnark-crypto/ecc/bn254"
	"github.com/consensys/gnark-crypto/ecc/bn254/fp"
	"github.com/consensys/gnark-crypto/ecc/bn254/fr"
	plonk "github.com/consensys/gnark/backend/plonk/bn254"
)

type VerifyingKey struct {
	*plonk.VerifyingKey
}

func (vk VerifyingKey) MarshalSolidity() ([]byte, error) {
	if len(vk.Qcp) != len(vk.CommitmentConstraintIndexes) {
		return nil, errors.New("len(vk.Qcp) != len(vk.CommitmentConstraintIndexes)")
	}

	appendFp := func(writer io.Writer, e *fp.Element) {
		b := e.Bytes()
		_, _ = writer.Write(b[:])
	}
	appendFr := func(writer io.Writer, e *fr.Element) {
		b := e.Bytes()
		_, _ = writer.Write(b[:])
	}
	appendG1 := func(writer io.Writer, e *ecc.G1Affine) {
		appendFp(writer, &e.X)
		appendFp(writer, &e.Y)
	}
	appendG2 := func(writer io.Writer, e *ecc.G2Affine) {
		appendFp(writer, &e.X.A1)
		appendFp(writer, &e.X.A0)
		appendFp(writer, &e.Y.A1)
		appendFp(writer, &e.Y.A0)
	}
	appendUint64 := func(writer io.Writer, e uint64) {
		b := binary.BigEndian.AppendUint64(make([]byte, 24), e)
		_, _ = writer.Write(b)
	}

	var b bytes.Buffer
	appendG2(&b, &vk.Kzg.G2[0])
	appendG2(&b, &vk.Kzg.G2[1])
	appendG1(&b, &vk.Kzg.G1)
	appendUint64(&b, vk.NbPublicVariables)
	appendUint64(&b, vk.Size)
	appendFr(&b, &vk.SizeInv)
	appendFr(&b, &vk.Generator)
	appendG1(&b, &vk.Ql)
	appendG1(&b, &vk.Qr)
	appendG1(&b, &vk.Qm)
	appendG1(&b, &vk.Qo)
	appendG1(&b, &vk.Qk)
	appendG1(&b, &vk.S[0])
	appendG1(&b, &vk.S[1])
	appendG1(&b, &vk.S[2])
	appendFr(&b, &vk.CosetShift)
	appendUint64(&b, uint64(len(vk.CommitmentConstraintIndexes)))
	for _, e := range vk.Qcp {
		appendG1(&b, &e)
	}
	for _, e := range vk.CommitmentConstraintIndexes {
		appendUint64(&b, e)
	}

	if b.Len() != 1024+len(vk.CommitmentConstraintIndexes)*96 {
		return nil, errors.New("unexpected size")
	}

	return b.Bytes(), nil
}
