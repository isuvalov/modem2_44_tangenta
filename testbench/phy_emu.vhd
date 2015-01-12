library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;


entity phy_emu is
	generic(
		num:integer:=0
	);
	port (
	 clk: in std_logic;
	 rd: in std_logic;
	 dv: out std_logic;
	 dataout: out std_logic_vector(7 downto 0);
	 rx_dv: in std_logic;
	 datain: in std_logic_vector(7 downto 0);
	 rx_state: out std_logic
	);
end phy_emu;


architecture phy_emu of phy_emu is

component use_ipgen
port (
 clk: in std_logic;
 rd: in std_logic;
 dv: out std_logic;
 dataout: out std_logic_vector(7 downto 0)
);
end component;

component use_ipgen2
port (
 clk: in std_logic;
 rd: in std_logic;
 dv: out std_logic;
 dataout: out std_logic_vector(7 downto 0)
);
end component;

type Tflow_ctrl_packet is array (0 to 71) of std_logic_vector(7 downto 0);
constant flow_ctrl_packet_pause:Tflow_ctrl_packet:=
 (x"55",x"55",x"55",x"55",x"55",x"55",x"55",x"D5",

  x"01",x"80",x"C2",x"00",x"00",x"01",x"43",x"41",
  x"4D",x"00",x"00",x"00",x"88",x"08",x"00",x"01",

  x"FF",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",

  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",

  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"EC",x"C1",x"B2",x"4E"
);

constant flow_ctrl_packet_ok:Tflow_ctrl_packet:=
 (x"55",x"55",x"55",x"55",x"55",x"55",x"55",x"D5",

  x"01",x"80",x"C2",x"00",x"00",x"01",x"43",x"41",
  x"4D",x"00",x"00",x"00",x"88",x"08",x"00",x"01",

  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",

  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",

  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"68",x"AA",x"BD",x"37"
);


signal s_dv,work_now,work_nowT:std_logic:='1';
signal work_nowTa:std_logic_vector(243 downto 0);
signal cnt,p_cnt,c_cnt:std_logic_vector(7 downto 0);

signal i_cnt:integer:=0;
signal ssww:std_logic:='1';

signal start_cnt:integer:=0;
signal start_ce:std_logic:='0';

begin

rr: if num=0 generate
use_ipgen_inst:use_ipgen
port map(
 clk=>clk,
 rd=>work_now,
 dv=>s_dv,
 dataout=>dataout
);
end generate;

rr2: if num/=0 generate
use_ipgen_inst:use_ipgen2
port map(
 clk=>clk,
 rd=>work_now,
 dv=>s_dv,
 dataout=>dataout
);
end generate;

--ssww<=1 when ssww=0 else 2 when ssww=1 else 1 after 0.1 ms;
start_ce<='1';--'1' after 3 ms;

dv<=s_dv when work_now='1' else '0';
--dv<='0';

process(clk) is
begin
	if rising_edge(clk) then
		if i_cnt<51 then
			i_cnt<=i_cnt+1 after 0.1 ms;
		else
			i_cnt<=0;
		end if;

		if i_cnt>50 then
			ssww<='1';
		elsif i_cnt>30 then
			ssww<='1';
			--ssww<='0';
		end if;
		if s_dv='0' then
			work_now<=(work_nowTa(work_nowTa'Length-1) and ssww) and start_ce;
		end if;

		if rx_dv='0' then
--		if s_dv='0' then
			cnt<=(others=>'0');
			p_cnt<=(others=>'0');
			c_cnt<=(others=>'0');

		else
			cnt<=cnt+1;
			if cnt<=71 then
				if datain=flow_ctrl_packet_pause(conv_integer(cnt)) then
					p_cnt<=p_cnt+1;
				end if;
				if datain=flow_ctrl_packet_ok(conv_integer(cnt)) then
					c_cnt<=c_cnt+1;
				end if;
			end if; --#cnt

		end if;

			if work_nowT='1' then
				if p_cnt>=72 then
					work_nowT<='0';
				end if;
			else
				if c_cnt>=72 then
					work_nowT<='1';
				end if;
			end if;	

       work_nowTa<=work_nowTa(work_nowTa'Length-2 downto 0)&work_nowT;
	end if;
end process;

end phy_emu;
