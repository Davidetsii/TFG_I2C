
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity FSM_temp is
    generic(
                C_MEM_DEPTH     : integer := 4096;      -- Number of memory positions
                C_MEM_DEPTH_LG2 : integer := 12         -- Log2 of C_MEM_DEPTH
    );
    Port (      clk     : in std_logic;
                reset   : in std_logic;
                start   : in std_logic;
                stop    : in std_logic;
                on_off  : out std_logic;
                reset_i2c: out std_logic;
                sample_cnt_o  : out std_logic_vector(C_MEM_DEPTH_LG2-1 downto 0);
                done_o  : out std_logic;
                read_en_i     : in std_logic;
                timer_cnt_i   : in std_logic_vector(31 downto 0)
    );
end FSM_temp;

architecture Behavioral of FSM_temp is

    signal fq  : unsigned(31 downto 0);
    type machine is (IDLE, OPERATION);
    signal FSM  : machine;
    signal start_reg, start_s, stop_reg, stop_s     : std_logic;
    signal sample_cnt   :   unsigned(C_MEM_DEPTH_LG2-1 downto 0);

begin

-- REGISTROS
process(clk, reset)
begin
    if reset = '1' then
        start_reg   <= '0';
        start_s     <= '0';
        stop_reg    <= '0';
        stop_s      <= '0';

    elsif clk'event and clk = '1' then
        start_reg   <= start;
        start_s     <= start_reg;
        stop_reg    <= stop;
        stop_s      <= stop_s;     
    end if;
end process;


-- FSM
process(clk, reset)
begin
    if reset = '1' then
        on_off  <= '0';
        done_o  <= '0';
        FSM     <= IDLE;
        fq      <= (others => '0');
        reset_i2c <= '0';
            if read_en_i = '1' then
                sample_cnt <= (others => '1');
            else
                sample_cnt <= (others => '0');
            end if;
    elsif clk'event and clk = '1' then
        if FSM = IDLE then
            reset_i2c <= '0';
            on_off  <= '0';
            fq      <= (others => '0');
            if start_s = '0' and start_reg = '1' then
                FSM <= OPERATION;
            end if;
        elsif FSM = OPERATION then
            if fq = unsigned(timer_cnt_i) - 1 then
                if read_en_i = '0' then
                    on_off  <= '1';
                    if sample_cnt = C_MEM_DEPTH - 1 then
                        FSM <= IDLE;
                        done_o <= '1';
                    else
                        sample_cnt <= sample_cnt + 1;
                    end if;
                else
                    if sample_cnt = 0 then
                        FSM <= IDLE;
                        done_o <= '1';
                    else
                        sample_cnt <= sample_cnt - 1;
                    end if;
                end if;
                fq      <= (others => '0');
                reset_i2c <= '0'; 
            elsif stop_s = '0' and stop_reg = '1' then
                on_off  <= '0';
                FSM     <= IDLE;
                fq      <= (others => '0');  
                if read_en_i = '0' then
                    reset_i2c <= '1'; 
                end if;
            elsif fq = unsigned(timer_cnt_i) - 3  and read_en_i = '0' then
                reset_i2c <= '1';  
                fq <= fq + 1;    
            else
                fq <= fq + 1;
                on_off <= '0';
                reset_i2c <= '0'; 
            end if;
        end if;
    end if;
end process;

sample_cnt_o <= std_logic_vector(sample_cnt);

end Behavioral;
