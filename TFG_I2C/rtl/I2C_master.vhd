
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity I2C_master is
    generic (
            C_FREQ_SYS   : integer := 125000000;    -- 125 MHz
            C_FREQ_SCL   : integer := 100000        -- 100 KHz en SCL                            
    );
    Port ( 
            clk     : in std_logic;
            reset   : in std_logic;
            START   : in std_logic;     
            ADDRESS : in std_logic_vector(6 downto 0);
            DATA_IN : in std_logic_vector(7 downto 0);        
            DONE    : out std_logic;
            SDA     : inout std_logic;
            SCL     : out std_logic;
            DATA_READ: out std_logic_vector(7 downto 0);
            BYTES_W     : in std_logic_vector(1 downto 0);
            BYTES_R     : in std_logic_vector(1 downto 0)                   
    );
end I2C_master;

architecture Behavioral of I2C_master is

    signal stop_count, stop_scl, sipo, piso, stop_sda, zero_sda, reading, condition, ack_s, overflow, R_W, done_aux     : std_logic;
    signal div      : std_logic_vector(1 downto 0);

begin

    CONTADOR_125KHz : entity work.I2C_counter
        generic map(
                    C_FREQ_SYS  => C_FREQ_SYS,
                    C_FREQ_SCL  => C_FREQ_SCL
        )
        port map(
            clk         => clk,
            reset       => reset,
            stop        => stop_scl, 
            stop_count  => stop_count,
            condition   => condition,   
            DONE        => done_aux,  
            overflow    => overflow,
            SCL         => SCL,
            div         => div
        );


    FSM_1 : entity work.I2C_state(Behavioral)
        port map(
            clk         => clk,
            reset       => reset, 
            START       => START,  
            R_W         => R_W,  
            div         => div, 
            overflow    => overflow,
            SDA         => SDA,
            DONE        => DONE,
            done_aux    => done_aux,
            stop_count  => stop_count,
            stop_scl    => stop_scl,
            sipo        => sipo,
            piso        => piso,
            ack_s       => ack_s,
            stop_sda    => stop_sda,
            zero_sda    => zero_sda,
            reading     => reading,
            condition   => condition,
            BYTES_W     => BYTES_W,
            BYTES_R     => BYTES_R            
        );

    SDA_GEN : entity work.I2C_datasda(Behavioral)
    port map(
        clk         => clk,
        reset       => reset,
        overflow    => overflow, 
        R_W         => R_W,  
        DONE        => done_aux,       
        sipo        => sipo,
        piso        => piso,
        ack_s       => ack_s,
        stop_sda    => stop_sda,
        zero_sda    => zero_sda,
        reading     => reading,
        DATA_IN     => DATA_IN,
        ADDRESS     => ADDRESS,
        SDA         => SDA,
        div         => div,
        DATA_READ   => DATA_READ
    );

end Behavioral;
