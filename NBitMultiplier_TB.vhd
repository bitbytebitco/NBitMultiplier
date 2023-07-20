library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity NBitMultiplier_TB is
end entity;

architecture NBitMultiplier_TB_arch of NBitMultiplier_TB is
    
    constant t_clk_per : time := 62.5 ns;  -- Period of a 1000 MHz Clock
    constant n : integer := 32; -- # of Bits in Multiplier


    signal A_TB, B_TB, P32_TB: std_logic_vector( (n-1) downto 0);
    signal P_TB : std_logic_vector( ((n*2)-1) downto 0);
    signal SU_TB, HL_TB : std_logic;
    signal clock_TB, reset_TB, start_TB, done_clear_TB: std_logic;

    component NBitMultiplier
        generic (
            bits_wide : integer := 32
        );
        port(
            clk : in std_logic;
            rst : in std_logic;
            i_start : in std_logic;
            i_A : in std_logic_vector( (bits_wide-1) downto 0); -- multiplicand
            i_B : in std_logic_vector( (bits_wide-1) downto 0); -- multiplier
            i_SU : in std_logic := '0';                         -- 0: unsigned, 1: signed
            i_HL : in std_logic := '0';                         -- 0: lower 32-bits, 1: upper 32-bits
            i_done_clear : in std_logic := '0';
            o_busy : out std_logic;
            o_done : out std_logic;
            o_prod64 : out std_logic_vector( ((2*bits_wide)-1) downto 0);
            o_prod : out std_logic_vector( (bits_wide-1) downto 0)
        );
    
    end component;

    begin
    
    DUT : NBitMultiplier 
        generic map (
            bits_wide => n
        )
        port map(
            clk => clock_TB,
            rst => reset_TB,
            i_start => start_TB,
            i_A => A_TB, 
            i_B => B_TB,
            i_SU => SU_TB,
            i_HL => HL_TB,
            i_done_clear => done_clear_TB,
            o_prod64 => P_TB,
            o_prod => P32_TB
        );
        
    -------------------------------------------------------
      CLOCK_STIM : process
       begin
          clock_TB <= '1'; wait for 0.5*t_clk_per; 
          clock_TB <= '0'; wait for 0.5*t_clk_per; 
       end process;
    -------------------------------------------------------
          RESET_STIM : process
       begin
          reset_TB <= '0'; wait for 0.25*t_clk_per; 
          reset_TB <= '1'; wait;
       end process;
    -------------------------------------------------------
    STIM: process
	    begin
		

        start_TB <= '1'; wait for 1 *t_clk_per;
        start_TB <= '0'; 
        SU_TB <= '0';
		A_TB <= x"FFFFFFFF";
		B_TB <= x"FFFFFFFF";
		wait for 8 * t_clk_per;
		done_clear_TB <= '1'; wait for 1.25 *t_clk_per;
		done_clear_TB <= '0';
		wait for 4 * t_clk_per;
		

		start_TB <= '1'; wait for 1 *t_clk_per;
        start_TB <= '0'; 
        SU_TB <= '0';
		A_TB <= std_logic_vector(to_unsigned(25,n));
		B_TB <= std_logic_vector(to_unsigned(5,n));
		wait for 8 * t_clk_per;
		done_clear_TB <= '1'; wait for 1.5 *t_clk_per;
		done_clear_TB <= '0';
		wait for 4 * t_clk_per;
		
		
        start_TB <= '1'; wait for 1 *t_clk_per;
        start_TB <= '0'; 
        SU_TB <= '1';
		A_TB <= std_logic_vector(to_signed(-21, n));
		B_TB <= std_logic_vector(to_unsigned(2,n));
		wait for 8 * t_clk_per;
		done_clear_TB <= '1'; wait for 1.5 *t_clk_per;
		done_clear_TB <= '0';
		wait for 4 * t_clk_per;
		
	
	    start_TB <= '1'; wait for 1 *t_clk_per;
        start_TB <= '0'; 
        SU_TB <= '1';
		A_TB <= std_logic_vector(to_signed(-2147483648, n));
		B_TB <= std_logic_vector(to_unsigned(2147483647,n));
		wait for 8 * t_clk_per;
		done_clear_TB <= '1'; wait for 1.5 *t_clk_per;
		done_clear_TB <= '0';
		wait;
		
		
    end process;
    
end architecture;
