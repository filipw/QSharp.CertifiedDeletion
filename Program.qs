namespace QSharp.CertifiedDeletion {

    open Microsoft.Quantum.Logical;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    

    @EntryPoint()
    operation Main(decryptFlow: Bool) : Unit {
        let theta = [false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true];

        let r = [false, true, true, false, false, true, true, false, false, false, true, true, true, true, false, false];

        use qubits = Qubit[16];

        mutable r_z = [];
        mutable r_x = [];

        for i in 0..15 {
            // X basis
            if theta[i] { 
                if r[i] { // 1 is |->
                    X(qubits[i]);
                    H(qubits[i]); 
                } else { //0 is |+>
                    H(qubits[i]);
                }

                // save the r value to r_x
                set r_x += [r[i]]; 
            } else {  // Z basis
                if r[i] { // 1 is |1>
                    X(qubits[i]);
                } else { // 0 is |0>
                    I(qubits[i]);
                }

                // save the r value to r_z
                set r_z += [r[i]];
            }
        }

        Message($"R_z: {BoolArrayAsBinaryString(r_z)}");
        Message($"R_x: {BoolArrayAsBinaryString(r_x)}");
        Message("");

        // let's pick something silly with 8 bit length to encrypt
        let message = 4; 
        let binaryMessage = IntAsBoolArray(message, 8);
        Message($"Raw message: {BoolArrayAsBinaryString(binaryMessage)}");

        // encrypt by doing XOR between the message and r_z
        let encrypted = MappedByIndex((i, x) -> Xor(binaryMessage[i], x), r_z);
        Message($"Encrypted message: {BoolArrayAsBinaryString(encrypted)}");
        Message("");

        if decryptFlow {
            // decrypt flow
            Decrypt(qubits, theta, encrypted);
        } else {
            // delete and verify flow
            let deletion_proof = Delete(qubits);
            VerifyDeletion(theta, deletion_proof);
        }

        ResetAll(qubits);
    }

    operation Decrypt(qubits: Qubit[], theta: Bool[], encrypted: Bool[]) : Unit {
        // decrypt using theta as key
        // first obtain r_z by measuring only the qubits that were encoded in the Z basis
        mutable r_z_from_measurement = [];
        for i in 0..15 {
            if not theta[i] { 
                set r_z_from_measurement += [M(qubits[i]) == One];
            }
        }
        Message($"R_z from qubits: {BoolArrayAsBinaryString(r_z_from_measurement)}");

        // now perform XOR between the encrypted data and the r_z
        let decrypted = MappedByIndex((i, x) -> Xor(encrypted[i], x), r_z_from_measurement);

        // the decrypted data should be identical to raw message
        Message($"Decrypted message: {BoolArrayAsBinaryString(decrypted)}");
    }

    operation Delete(qubits: Qubit[]) : Bool[] {
        mutable deletion_proof = [];
        for i in 0..15 {
            set deletion_proof += [Measure([PauliX], [qubits[i]]) == One];
        }

        return deletion_proof;
    }

    operation VerifyDeletion(theta: Bool[], d: Bool[]) : Unit {
        mutable d_x = [];
        for i in 0..15 {
            if theta[i] {
                set d_x += [d[i]];
            }
        }

        // now verify the deletion by comparing d_x to r_x - they must be identical
        Message($"R_x from qubits: {BoolArrayAsBinaryString(d_x)}");
    }

    function BoolArrayAsBinaryString(arr : Bool[]) : String {
        mutable output = "";
        for entry in arr {
            set output += entry ? "1" | "0";
        }
        return output;
    }
}

