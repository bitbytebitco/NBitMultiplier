----------------------------------------------------------------------
-- File name   : NBitMultiplier.vhd
--
-- Project     : NBitMultiplier
--
-- Description : An Unsigned & Signed Integer Multiplier of N-bit length, which
--               can be spec'd through the generic param. `bits_wide`
--
-- Author(s)   : Zachary Becker
--               bitbytebitco@gmail.com
----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all; 

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

architecture NBitMultiplier_arch of NBitMultiplier is

        -- signal and constant declarations
        type state_type is (IDLE, BUSY, VALID_WAIT);
        signal current_state, next_state : state_type;
        
        constant n : integer := bits_wide; -- # of Bits in Multiplier
        signal k : integer := 0;
        
        signal w_STATE : std_logic_vector(1 downto 0) := "00"; -- IDLE
        
        signal w_A : std_logic_vector( (bits_wide-1) downto 0);
        signal w_B : std_logic_vector( (bits_wide-1) downto 0);
        signal w_An : std_logic_vector( (bits_wide-1) downto 0);
        signal w_Bn : std_logic_vector( (bits_wide-1) downto 0);
        signal w_SB : std_logic;
       
        -- NBit 
        signal c: std_logic_vector( (n*(n-1)-1) downto 0);          
        signal ands : std_logic_vector( ((n*n)-1) downto 0);
        signal sums : std_logic_vector( (n*(n-1)-1) downto 0);
        signal w_prod, w_prod_n, w_prod_comp : std_logic_vector( ((n*2)-1) downto 0);
        
        signal clk_cnt: integer := 0;
        signal cnt_en : std_logic := '0';
       
        -- component declarations       
        component full_adder is
            port(fa_A, fa_B, fa_Cin  : in std_logic;
                 fa_Sum, fa_Cout: out std_logic);
        end component;

    begin
    
        w_An <= not i_A;
        w_Bn <= not i_B;
        
        
        ------------------------------------------------------------------------------------------------------------------------------------
        -- STATE MEMORY
        ------------------------------------------------------------------------------------------------------------------------------------
        STATE_MEMORY : process(clk, rst, current_state)
            begin
                if(rst = '0') then
                    -- default
                    current_state <= IDLE;
                    clk_cnt <= 0;
                elsif(rising_edge(clk)) then
                    current_state <= next_state;
                    
                    if(current_state = BUSY) then
                        clk_cnt <= clk_cnt + 1;
                    end if;
                    
                    if(current_state = VALID_WAIT) then
                        clk_cnt <= 0;
                    end if;
                end if;
        end process;
        
        
        ------------------------------------------------------------------------------------------------------------------------------------
        -- NEXT STATE LOGIC
        ------------------------------------------------------------------------------------------------------------------------------------
        NEXT_STATE_LOGIC : process(current_state, i_start, i_done_clear, clk_cnt)
            begin
                case current_state is
                    when IDLE => 
                        if(i_start = '1') then
                            next_state <= BUSY;
                        else 
                            next_state <= IDLE;
                        end if;
                    when BUSY => 
                        if(clk_cnt >= 2) then
                            next_state <= VALID_WAIT;
                        else 
                            next_state <= BUSY;
                        end if;     
                    when VALID_WAIT => 
                        if(i_done_clear = '1') then
                            next_state <= IDLE;
                        else 
                            next_state <= VALID_WAIT;
                        end if;
                    when others => next_state <= IDLE;
                end case;
        end process;
        
        ------------------------------------------------------------------------------------------------------------------------------------
        -- OUTPUT LOGIC
        ------------------------------------------------------------------------------------------------------------------------------------
        OUTPUT_LOGIC : process(clk_cnt, current_state, next_state, i_SU, i_HL, w_SB, w_prod_comp, w_prod)
            begin
                case current_state is
                    when IDLE => 
                        o_busy <= '0';
                        o_done <= '0';
                        o_prod(31 downto 0) <= (others => 'U');
                        o_prod64(63 downto 0) <= (others => 'U');
                        
                    when BUSY | VALID_WAIT =>
                        
                        if(current_state = BUSY) then
                            o_busy <= '1';
                            o_done <= '0';
                        elsif(current_state = VALID_WAIT) then
                            o_busy <= '0';
                            o_done <= '1';
                        else 
                            o_busy <= 'U';
                            o_done <= 'U';
                        end if;
                    
                        if(i_SU = '1') then
                            -- signed
                            
                            if(w_SB = '1') then -- if product sign-bit HIGH take 2's comp 
                                o_prod64 <= w_prod_comp;
                                if(i_HL = '1') then
                                    o_prod <= w_prod_comp(((2*n)-1) downto n);
                                else
                                    o_prod <= w_prod_comp((n-1) downto 0);
                                end if;
                            else
                                o_prod64 <= w_prod;
                                if(i_HL = '1') then
                                    o_prod <= w_prod(((2*n)-1) downto n);
                                else
                                    o_prod <= w_prod((n-1) downto 0);
                                end if;
                                
                            end if;
                            
                        else
                            -- unsigned
                            o_prod64 <= w_prod;
                            
                            if(i_HL = '1') then
                                o_prod <= w_prod(((2*n)-1) downto n);
                            elsif(i_HL = '0') then
                                o_prod <= w_prod((n-1) downto 0);
                            end if;
                        end if;
                    when others => 
                        o_busy <= '0';
                        o_done <= '0';
                        o_prod(31 downto 0) <= (others => 'U');
                        o_prod64(63 downto 0) <= (others => 'U');
                end case;
        end process;
        
        
    
        -- obtaining 2's comp of negative values when i_SU is HIGH (handling signed inputs)
        SIGNED_UNSIGNED : process(clk, i_start, rst, i_A, i_B, i_SU, next_state)
--            variable SumA_uns : unsigned(n downto 0);
--            variable SumB_uns : unsigned(n downto 0);
            
            begin
            
                if(next_state = BUSY) then
                
                    if(rising_edge(clk)) then
                        if(i_SU = '0') then
                            w_A <= i_A;
                            w_B <= i_B;
                        elsif(i_SU = '1') then
                        
                            if(i_A(n-1) = '1') then
                                w_A <= (not i_A) + 1;
                            else 
                                w_A <= i_A;
                            end if;
                            
                            if(i_B(n-1) = '1') then
                                w_B <= (not i_B) + 1;
                            else
                                w_B <= i_B;
                            end if;
                        end if;
                    end if;
                    
                end if;          
        end process;
    
    
    
        ------------------------------------------------------------------------------------------------------------------------------------
        -- COMBINATIONAL LOGIC
        ------------------------------------------------------------------------------------------------------------------------------------     
        
        -- generate `ands` values    
        i_gen: for i in 0 to n-1 generate
            j_gen : for j in 0 to n-1 generate
                ands((n*i + j)) <= w_A(j) and w_B(i);
            end generate;
        end generate;
          
        -- generate `sums` and `c` (carry-outs)
        k_gen: for k in 0 to (n-2) generate
            in1: if (k = 0) generate -- first row
                l0a : for l in 0 to (n-1) generate
                    l0a0: if( l = 0 ) generate -- first column 
                        uu : full_adder port map (fa_A => ands(1), fa_B => ands(n), fa_Cin => '0', fa_Sum => sums(0), fa_Cout => c(0) );
                    end generate;
                    l0a1 : if (l>0 and l <= (n-2)) generate -- middle columns 
                        uu : full_adder port map (fa_A => ands(l+1), fa_B => ands(n+l), fa_Cin => c(l-1), fa_Sum => sums(l), fa_Cout => c(l) );       
                    end generate;
                    l0a2 : if (l = (n-1)) generate -- last column 
                        uu : full_adder port map (fa_A => '0', fa_B => ands((n*2)-1), fa_Cin => c(l-1), fa_Sum => sums(l), fa_Cout => c(l) );       
                    end generate;
                end generate l0a;
            end generate in1;
            
            in2: if (k > 0) generate -- all other rows
                l0b : for l in 0 to (n-1) generate
                    l0b0: if( l = 0 ) generate -- first column 
                        uu : full_adder port map (fa_A => sums(((k-1)*n)+(l+1)), fa_B => ands(n*(k+1)), fa_Cin => '0', fa_Sum => sums((n*k)), fa_Cout => c((n*k)) );
                    end generate;
                    l0b1 : if (l>0 and l <= (n-2)) generate -- middle columns 
                        uu : full_adder port map (fa_A => sums((n*(k-1))+(l+1)), fa_B => ands((n*(k+1))+l), fa_Cin => c((n*k)+l-1), fa_Sum => sums((n*(k))+l), fa_Cout => c((n*(k))+l) );       
                    end generate;
                    l0b2 : if (l = (n-1)) generate -- last column 
                        uu : full_adder port map (fa_A => c((n*k)-1), fa_B => ands((n*(k+1))+l), fa_Cin => c((n*k)+(l-1)), fa_Sum => sums((n*k)+l), fa_Cout => c((n*k)+l) );       
                    end generate;   
                end generate;
            end generate in2;
            
        end generate;
        
     
        -- Product Output (populating w_prod)
        w_prod(0) <= ands(0); -- BIT0
        output1 : for o in 1 to (n-1) generate 
            w_prod(o) <= sums(n*(o-1));
        end generate;
        
        output2 : for p in 0 to (n-2) generate
            w_prod(n+p) <= sums(((n-2)*n)+(p+1));
        end generate;
        w_prod((n*2)-1) <= c(n*(n-1)-1); -- BIT N
        
        
        -- 2's comp of product
        w_prod_n <= not w_prod;      -- inverted w_prod
        w_prod_comp <= w_prod_n + 1; -- 2's comp
        
        -- calculating product sign-bit
        w_SB <= i_A(n-1) xor i_B(n-1);
        
        
         
end architecture;
