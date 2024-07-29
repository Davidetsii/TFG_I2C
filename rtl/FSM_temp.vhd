
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
                done_edge    : in std_logic;
                start_i2c  : out std_logic;
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
    signal ena_temp, start_timer, start_fsm     : std_logic;
    signal sample_cnt   :   unsigned(C_MEM_DEPTH_LG2-1 downto 0);

begin

-- Contador Puntero
process(clk, reset)
begin
    if reset = '1' then
        sample_cnt <= (others => '0');
    elsif clk'event and clk = '1' then
        if done_edge = '1'  and sample_cnt <= C_MEM_DEPTH - 2 then
            sample_cnt <= sample_cnt + 1;
        end if;
        if read_en_i = '1' and sample_cnt > 0 then
            sample_cnt <= sample_cnt - 1;
        end if;
    end if;
end process;

-- Temporizador
process(clk, reset)
begin
    if reset = '1' then
        fq <= (others => '0');
        reset_i2c <= '0';
        start_timer <= '0';
    elsif clk'event and clk = '1' then
        if ena_temp = '1' then
        
            fq <= fq + 1;
            start_timer <= '0';
            if fq = unsigned(timer_cnt_i) - 1 then
                fq <= (others => '0');
                start_timer <= '1';
            end if;
        else
            fq <= (others => '0');
            start_timer <= '0';
        end if;
    end if;
end process;

-- FSM
process(clk, reset)
begin
    if reset = '1' then
        FSM     <= IDLE;
        ena_temp <= '0';
        done_o  <= '0';
        start_fsm <= '0';
    elsif clk'event and clk = '1' then
        if FSM = IDLE then
          
            if start = '1' then
                FSM <= OPERATION;
                ena_temp <= '1';
                done_o  <= '0';
                start_fsm <= '1';
            end if;
        elsif FSM = OPERATION then
            start_fsm <= '0';
            if (sample_cnt = C_MEM_DEPTH - 1  and done_edge = '1') or stop = '1' then
                FSM <= IDLE;
                ena_temp <= '0';
                done_o  <= '1';
            end if;
        end if;
    end if;
end process;

sample_cnt_o <= std_logic_vector(sample_cnt);
start_i2c <= start_fsm or start_timer;

end Behavioral;
