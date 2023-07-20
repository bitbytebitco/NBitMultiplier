# NBitMultiplier
N-Bit hardware integer multiplier (unsigned/signed) written in VHDL

```
entity NBitMultiplier is
    generic (
        bits_wide : integer := 32
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        i_start : in std_logic;
        i_A : in std_logic_vector( (bits_wide-1) downto 0); -- multiplicand
        i_B : in std_logic_vector( (bits_wide-1) downto 0); -- multiplier
        i_SU : in std_logic;                         -- 0: unsigned, 1: signed
        i_HL : in std_logic;                         -- 0: lower 32-bits, 1: upper 32-bits
        i_done_clear : in std_logic;
        o_busy : out std_logic;
        o_done : out std_logic;
        o_prod64 : out std_logic_vector( ((2*bits_wide)-1) downto 0);
        o_prod : out std_logic_vector( (bits_wide-1) downto 0)
    );
end entity;
```

## Simulation Waveform
![alt text](https://github.com/bitbytebitco/NBitMultiplier/blob/master/NBitMultiplier_Simulation_Wave.png?raw=true)
