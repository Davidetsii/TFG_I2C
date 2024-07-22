
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity FSM_temp is
    generic (
                freq    : integer := 1000000
    );
    Port (      clk     : in std_logic;
                reset   : in std_logic;
                start   : in std_logic;
                stop    : in std_logic;
                done    : in std_logic;
                on_off  : out std_logic;
                cont    : out std_logic;
                reset_i2c: out std_logic
    );
end FSM_temp;

architecture Behavioral of FSM_temp is

    signal fq  : integer range freq - 1 downto 0;
    type machine is (OFF, COUNTING, WAITING);
    signal FSM  : machine;
    signal start_reg, start_s, stop_reg, stop_s, done_reg, done_s   : std_logic;

begin

-- REGISTROS
process(clk, reset)
begin
    if reset = '1' then
        start_reg   <= '0';
        start_s     <= '0';
        stop_reg    <= '0';
        stop_s      <= '0';
        done_reg    <= '0';
        done_s      <= '0';
    elsif clk'event and clk = '1' then
        start_reg   <= start;
        start_s     <= start_reg;
        stop_reg    <= stop;
        stop_s      <= stop_s;
        done_reg    <= done;
        done_s      <= done_reg;        
    end if;
end process;


-- FSM
process(clk, reset)
begin
    if reset = '1' then
        on_off  <= '0';
        FSM     <= OFF;
        fq      <= 0;
        cont    <= '0';
        reset_i2c <= '0';
    elsif clk'event and clk = '1' then
        if FSM = OFF then
            reset_i2c <= '0';
            on_off  <= '0';
            fq      <= 0;
            cont    <= '0';
            if start_s = '0' and start_reg = '1' then
                FSM <= COUNTING;
            else
                FSM <= OFF;
            end if;
        elsif FSM = COUNTING then
            cont    <= '0';
            if fq = freq - 1 then
                on_off  <= '1';
                FSM     <= WAITING;
                reset_i2c <= '0'; 
            elsif stop_s = '0' and stop_reg = '1' then
                on_off  <= '0';
                FSM     <= OFF;
                fq      <= 0;  
                reset_i2c <= '1'; 
            elsif fq = freq - 3 then
                reset_i2c <= '1';  
                fq <= fq + 1;    
            else
                fq <= fq + 1;
                on_off <= '0';
                reset_i2c <= '0'; 
            end if;
        else
            on_off  <= '0';
            reset_i2c <= '0'; 
            if done_s = '0' and done_reg = '1' then
                cont    <= '1';
                fq      <= 0;
                FSM     <= COUNTING;
            elsif stop_s = '0' and stop_reg = '1' then
                cont    <= '0';
                fq      <= 0;
                FSM     <= OFF;
            else
                cont    <= '0';
            end if;
        end if;
    end if;
end process;

end Behavioral;
