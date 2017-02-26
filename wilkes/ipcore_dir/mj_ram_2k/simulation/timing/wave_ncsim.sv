
 
 
 




window new WaveWindow  -name  "Waves for BMG Example Design"
waveform  using  "Waves for BMG Example Design"


      waveform add -signals /mj_ram_2k_tb/status
      waveform add -signals /mj_ram_2k_tb/mj_ram_2k_synth_inst/bmg_port/CLKA
      waveform add -signals /mj_ram_2k_tb/mj_ram_2k_synth_inst/bmg_port/ADDRA
      waveform add -signals /mj_ram_2k_tb/mj_ram_2k_synth_inst/bmg_port/DINA
      waveform add -signals /mj_ram_2k_tb/mj_ram_2k_synth_inst/bmg_port/WEA
      waveform add -signals /mj_ram_2k_tb/mj_ram_2k_synth_inst/bmg_port/DOUTA
console submit -using simulator -wait no "run"
