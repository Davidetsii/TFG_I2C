
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_master is
    generic (
            C_FREQ_SYS   : integer := 100000000;    -- 100 MHz
            C_FREQ_I2C   : integer := 100000        -- 100 KHz en SCL                            
    );
    Port ( 
            clk     : in std_logic;
            reset_n : in std_logic;
            start   : in std_logic;     
            address : in std_logic_vector(6 downto 0);
            data_in : in std_logic_vector(7 downto 0);        
            done    : out std_logic;
            sda_in  : in std_logic;
            sda_out : out std_logic;
            sda_en  : out std_logic;
            scl_in  : in std_logic;
            scl_out : out std_logic;
            scl_en  : out std_logic;
            data_out: out std_logic_vector(15 downto 0);
            r_w     : in std_logic                 
    );
end i2c_master;

architecture Behavioral of i2c_master is

    signal stop_count, stop_scl, sipo, piso, stop_sda, zero_sda, reading, condition, ack_s, overflow, done_aux, r_w_inter     : std_logic;
    signal div      : std_logic_vector(1 downto 0);

begin

    CONTADOR_125KHz : entity work.I2C_counter
        generic map(
                    C_FREQ_SYS  => C_FREQ_SYS,
                    C_FREQ_I2C  => C_FREQ_I2C
        )
        port map(
            clk         => clk,
            reset_n     => reset_n,
            stop        => stop_scl, 
            stop_count  => stop_count,
            condition   => condition,   
            done        => done_aux,  
            overflow    => overflow,
            scl_in      => scl_in,
            scl_out     => scl_out,
            scl_en      => scl_en,
            div         => div
        );


    FSM_1 : entity work.I2C_state(Behavioral)
        port map(
            clk         => clk,
            reset_n     => reset_n, 
            start       => start,  
            r_w_inter   => r_w_inter,  
            div         => div, 
            overflow    => overflow,
            sda_in      => sda_in,
            done        => done,
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
            operation   => r_w        
        );

    SDA_GEN : entity work.I2C_datasda(Behavioral)
    port map(
        clk         => clk,
        reset_n     => reset_n,
        overflow    => overflow, 
        r_w         => r_w_inter, 
        done        => done_aux,       
        sipo        => sipo,
        piso        => piso,
        ack_s       => ack_s,
        stop_sda    => stop_sda,
        zero_sda    => zero_sda,
        reading     => reading,
        data_in     => data_in,
        address     => address,
        sda_in      => sda_in,
        sda_out     => sda_out,
        sda_en      => sda_en,
        div         => div,
        data_read   => data_out
    );

end Behavioral;
