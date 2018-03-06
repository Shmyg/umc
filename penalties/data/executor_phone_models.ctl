LOAD DATA
INFILE *
REPLACE
INTO TABLE EXECUTOR.PHONE_MODELS
FIELDS TERMINATED BY ';'
 (
  model_id                   ,
  atcode                     ,
  model_name                 ,
  entdate                    DATE(12) "DD.MM.YYYY",
  entuser                    
 )


BEGINDATA
1;1;ALCATEL-700;26.06.2002;TSLOBOD
2;1;ALCATEL-500;26.06.2002;TSLOBOD
3;1;ALCATEL-501;26.06.2002;TSLOBOD
4;1;ALCATEL-310 ;26.06.2002;TSLOBOD
5;1;ALCATEL-302;26.06.2002;TSLOBOD
6;1;ALCATEL-301;26.06.2002;TSLOBOD
7;1;ALCATEL-511;26.06.2002;TSLOBOD
8;1;ERICSSON R380;26.06.2002;TSLOBOD
9;1;ERICSSON R320S;26.06.2002;TSLOBOD
10;1;ERICSON t39m;26.06.2002;TSLOBOD
11;1;ERICSSON t29S;26.06.2002;TSLOBOD
12;1;ERICSSON T20S;26.06.2002;TSLOBOD
13;1;ERICSSON T28s;26.06.2002;TSLOBOD
14;1;ERICSSON T18s;26.06.2002;TSLOBOD
15;1;ERICSSON R310S;26.06.2002;TSLOBOD
16;1;ERICSSON A2618s;26.06.2002;TSLOBOD
17;1;ERICSSON A1018;26.06.2002;TSLOBOD
18;1;MOTOROLA V66;26.06.2002;TSLOBOD
19;1;MOTOROLA V3690;26.06.2002;TSLOBOD
20;1;MOTOROLA v50;26.06.2002;TSLOBOD
21;1;MOTOROLA t280;26.06.2002;TSLOBOD
22;1;MOTOROLA L7089;26.06.2002;TSLOBOD
23;1;MOTOROLA P7389;26.06.2002;TSLOBOD
24;1;MOTOROLA TI 250;26.06.2002;TSLOBOD
25;1;MOTOROLA t192;26.06.2002;TSLOBOD
26;1;MOTOROLA V2288;26.06.2002;TSLOBOD
27;1;MOTOROLA V3688;26.06.2002;TSLOBOD
28;1;NOKIA 9210 +;26.06.2002;TSLOBOD
29;1;NOKIA 9210 Comm;26.06.2002;TSLOBOD
30;1;NOKIA-8890;26.06.2002;TSLOBOD
31;1;NOKIA-8850 ;26.06.2002;TSLOBOD
32;1;NOKIA 9110;26.06.2002;TSLOBOD
33;1;NOKIA 8310;26.06.2002;TSLOBOD
34;1;NOKIA 6510;26.06.2002;TSLOBOD
35;1;NOKIA 6310;26.06.2002;TSLOBOD
36;1;NOKIA 6250;26.06.2002;TSLOBOD
37;1;NOKIA 8210;26.06.2002;TSLOBOD
38;1;NOKIA 5510;26.06.2002;TSLOBOD
39;1;NOKIA-7110 ;26.06.2002;TSLOBOD
40;1;NOKIA-6210 ;26.06.2002;TSLOBOD
41;1;NOKIA 5210;26.06.2002;TSLOBOD
42;1;NOKIA 3210;26.06.2002;TSLOBOD
43;1;NOKIA-3310 ;26.06.2002;TSLOBOD
44;1;NOKIA-8810 ;26.06.2002;TSLOBOD
45;1;NOKIA 6150;26.06.2002;TSLOBOD
46;1;NOKIA 8110;26.06.2002;TSLOBOD
47;1;NOKIA 5110;26.06.2002;TSLOBOD
48;1;PANASONIC GD-92;26.06.2002;TSLOBOD
49;1;PANASONIC GD-93;26.06.2002;TSLOBOD
50;1;PANASONIC GD-52;26.06.2002;TSLOBOD
51;1;PANASONIC GD-75;26.06.2002;TSLOBOD
52;1;PANASONIC GD-95;26.06.2002;TSLOBOD
53;1;PHILIPS XENIUM;26.06.2002;TSLOBOD
54;1;PHILIPS OZEO;26.06.2002;TSLOBOD
55;1;PHILLIPS SAVVY TCD128;26.06.2002;TSLOBOD
56;1;PHILIPS GENIE;26.06.2002;TSLOBOD
57;1;PHILIPS DIGA;26.06.2002;TSLOBOD
58;1;SAMSUNG A400;26.06.2002;TSLOBOD
59;1;SAMSUNG A300;26.06.2002;TSLOBOD
60;1;SAMSUNG R200;26.06.2002;TSLOBOD
61;1;SAMSUNG R210;26.06.2002;TSLOBOD
62;1;SAMSUNG N400;26.06.2002;TSLOBOD
63;1;SAGEM RC815;26.06.2002;TSLOBOD
64;1;SAGEM RC815;26.06.2002;TSLOBOD
65;1;SIEMENS SL45;26.06.2002;TSLOBOD
66;1;SIEMENS me45;26.06.2002;TSLOBOD
67;1;SIEMENS s45;26.06.2002;TSLOBOD
68;1;SIEMENS S35;26.06.2002;TSLOBOD
69;1;SIEMENS C45;26.06.2002;TSLOBOD
70;1;SIEMENS m35;26.06.2002;TSLOBOD
71;1;SIEMENS m35i;26.06.2002;TSLOBOD
72;1;SIEMENS c35;26.06.2002;TSLOBOD
73;1;SIEMENS c35i;26.06.2002;TSLOBOD
74;1;SIEMENS C35;26.06.2002;TSLOBOD
75;1;SIEMENS a40;26.06.2002;TSLOBOD
76;2;ALCATEL-700;26.06.2002;TSLOBOD
77;2;ALCATEL-500;26.06.2002;TSLOBOD
78;2;ALCATEL-501;26.06.2002;TSLOBOD
79;2;ALCATEL-310 ;26.06.2002;TSLOBOD
80;2;ALCATEL-302;26.06.2002;TSLOBOD
81;2;ALCATEL-301;26.06.2002;TSLOBOD
82;2;ALCATEL-511;26.06.2002;TSLOBOD
83;2;ERICSSON R380;26.06.2002;TSLOBOD
84;2;ERICSSON R320S;26.06.2002;TSLOBOD
85;2;ERICSON t39m;26.06.2002;TSLOBOD
86;2;ERICSSON t29S;26.06.2002;TSLOBOD
87;2;ERICSSON T20S;26.06.2002;TSLOBOD
88;2;ERICSSON T28s;26.06.2002;TSLOBOD
89;2;ERICSSON T18s;26.06.2002;TSLOBOD
90;2;ERICSSON R310S;26.06.2002;TSLOBOD
91;2;ERICSSON A2618s;26.06.2002;TSLOBOD
92;2;ERICSSON A1018;26.06.2002;TSLOBOD
93;2;MOTOROLA V66;26.06.2002;TSLOBOD
94;2;MOTOROLA V3690;26.06.2002;TSLOBOD
95;2;MOTOROLA v50;26.06.2002;TSLOBOD
96;2;MOTOROLA t280;26.06.2002;TSLOBOD
97;2;MOTOROLA L7089;26.06.2002;TSLOBOD
98;2;MOTOROLA P7389;26.06.2002;TSLOBOD
99;2;MOTOROLA TI 250;26.06.2002;TSLOBOD
100;2;MOTOROLA t192;26.06.2002;TSLOBOD
101;2;MOTOROLA V2288;26.06.2002;TSLOBOD
102;2;MOTOROLA V3688;26.06.2002;TSLOBOD
103;2;NOKIA 9210 +;26.06.2002;TSLOBOD
104;2;NOKIA 9210 Comm;26.06.2002;TSLOBOD
105;2;NOKIA-8890;26.06.2002;TSLOBOD
106;2;NOKIA-8850 ;26.06.2002;TSLOBOD
107;2;NOKIA 9110;26.06.2002;TSLOBOD
108;2;NOKIA 8310;26.06.2002;TSLOBOD
109;2;NOKIA 6510;26.06.2002;TSLOBOD
110;2;NOKIA 6310;26.06.2002;TSLOBOD
111;2;NOKIA 6250;26.06.2002;TSLOBOD
112;2;NOKIA 8210;26.06.2002;TSLOBOD
113;2;NOKIA 5510;26.06.2002;TSLOBOD
114;2;NOKIA-7110 ;26.06.2002;TSLOBOD
115;2;NOKIA-6210 ;26.06.2002;TSLOBOD
116;2;NOKIA 5210;26.06.2002;TSLOBOD
117;2;NOKIA 3210;26.06.2002;TSLOBOD
118;2;NOKIA-3310 ;26.06.2002;TSLOBOD
119;2;NOKIA-8810 ;26.06.2002;TSLOBOD
120;2;NOKIA 6150;26.06.2002;TSLOBOD
121;2;NOKIA 8110;26.06.2002;TSLOBOD
122;2;NOKIA 5110;26.06.2002;TSLOBOD
123;2;PANASONIC GD-92;26.06.2002;TSLOBOD
124;2;PANASONIC GD-93;26.06.2002;TSLOBOD
125;2;PANASONIC GD-52;26.06.2002;TSLOBOD
126;2;PANASONIC GD-75;26.06.2002;TSLOBOD
127;2;PANASONIC GD-95;26.06.2002;TSLOBOD
128;2;PHILIPS XENIUM;26.06.2002;TSLOBOD
129;2;PHILIPS OZEO;26.06.2002;TSLOBOD
130;2;PHILLIPS SAVVY TCD128;26.06.2002;TSLOBOD
131;2;PHILIPS GENIE;26.06.2002;TSLOBOD
132;2;PHILIPS DIGA;26.06.2002;TSLOBOD
133;2;SAMSUNG A400;26.06.2002;TSLOBOD
134;2;SAMSUNG A300;26.06.2002;TSLOBOD
135;2;SAMSUNG R200;26.06.2002;TSLOBOD
136;2;SAMSUNG R210;26.06.2002;TSLOBOD
137;2;SAMSUNG N400;26.06.2002;TSLOBOD
138;2;SAGEM RC815;26.06.2002;TSLOBOD
139;2;SAGEM RC815;26.06.2002;TSLOBOD
140;2;SIEMENS SL45;26.06.2002;TSLOBOD
141;2;SIEMENS me45;26.06.2002;TSLOBOD
142;2;SIEMENS s45;26.06.2002;TSLOBOD
143;2;SIEMENS S35;26.06.2002;TSLOBOD
144;2;SIEMENS C45;26.06.2002;TSLOBOD
145;2;SIEMENS m35;26.06.2002;TSLOBOD
146;2;SIEMENS m35i;26.06.2002;TSLOBOD
147;2;SIEMENS c35;26.06.2002;TSLOBOD
148;2;SIEMENS c35i;26.06.2002;TSLOBOD
149;2;SIEMENS C35;26.06.2002;TSLOBOD
150;2;SIEMENS a40;26.06.2002;TSLOBOD
151;3;ALCATEL-700;26.06.2002;TSLOBOD
152;3;ALCATEL-500;26.06.2002;TSLOBOD
153;3;ALCATEL-501;26.06.2002;TSLOBOD
154;3;ALCATEL-310 ;26.06.2002;TSLOBOD
155;3;ALCATEL-302;26.06.2002;TSLOBOD
156;3;ALCATEL-301;26.06.2002;TSLOBOD
157;3;ALCATEL-511;26.06.2002;TSLOBOD
158;3;ERICSSON R380;26.06.2002;TSLOBOD
159;3;ERICSSON R320S;26.06.2002;TSLOBOD
160;3;ERICSON t39m;26.06.2002;TSLOBOD
161;3;ERICSSON t29S;26.06.2002;TSLOBOD
162;3;ERICSSON T20S;26.06.2002;TSLOBOD
163;3;ERICSSON T28s;26.06.2002;TSLOBOD
164;3;ERICSSON T18s;26.06.2002;TSLOBOD
165;3;ERICSSON R310S;26.06.2002;TSLOBOD
166;3;ERICSSON A2618s;26.06.2002;TSLOBOD
167;3;ERICSSON A1018;26.06.2002;TSLOBOD
168;3;MOTOROLA V66;26.06.2002;TSLOBOD
169;3;MOTOROLA V3690;26.06.2002;TSLOBOD
170;3;MOTOROLA v50;26.06.2002;TSLOBOD
171;3;MOTOROLA t280;26.06.2002;TSLOBOD
172;3;MOTOROLA L7089;26.06.2002;TSLOBOD
173;3;MOTOROLA P7389;26.06.2002;TSLOBOD
174;3;MOTOROLA TI 250;26.06.2002;TSLOBOD
175;3;MOTOROLA t192;26.06.2002;TSLOBOD
176;3;MOTOROLA V2288;26.06.2002;TSLOBOD
177;3;MOTOROLA V3688;26.06.2002;TSLOBOD
178;3;NOKIA 9210 +;26.06.2002;TSLOBOD
179;3;NOKIA 9210 Comm;26.06.2002;TSLOBOD
180;3;NOKIA-8890;26.06.2002;TSLOBOD
181;3;NOKIA-8850 ;26.06.2002;TSLOBOD
182;3;NOKIA 9110;26.06.2002;TSLOBOD
183;3;NOKIA 8310;26.06.2002;TSLOBOD
184;3;NOKIA 6510;26.06.2002;TSLOBOD
185;3;NOKIA 6310;26.06.2002;TSLOBOD
186;3;NOKIA 6250;26.06.2002;TSLOBOD
187;3;NOKIA 8210;26.06.2002;TSLOBOD
188;3;NOKIA 5510;26.06.2002;TSLOBOD
189;3;NOKIA-7110 ;26.06.2002;TSLOBOD
190;3;NOKIA-6210 ;26.06.2002;TSLOBOD
191;3;NOKIA 5210;26.06.2002;TSLOBOD
192;3;NOKIA 3210;26.06.2002;TSLOBOD
193;3;NOKIA-3310 ;26.06.2002;TSLOBOD
194;3;NOKIA-8810 ;26.06.2002;TSLOBOD
195;3;NOKIA 6150;26.06.2002;TSLOBOD
196;3;NOKIA 8110;26.06.2002;TSLOBOD
197;3;NOKIA 5110;26.06.2002;TSLOBOD
198;3;PANASONIC GD-92;26.06.2002;TSLOBOD
199;3;PANASONIC GD-93;26.06.2002;TSLOBOD
200;3;PANASONIC GD-52;26.06.2002;TSLOBOD
201;3;PANASONIC GD-75;26.06.2002;TSLOBOD
202;3;PANASONIC GD-95;26.06.2002;TSLOBOD
203;3;PHILIPS XENIUM;26.06.2002;TSLOBOD
204;3;PHILIPS OZEO;26.06.2002;TSLOBOD
205;3;PHILLIPS SAVVY TCD128;26.06.2002;TSLOBOD
206;3;PHILIPS GENIE;26.06.2002;TSLOBOD
207;3;PHILIPS DIGA;26.06.2002;TSLOBOD
208;3;SAMSUNG A400;26.06.2002;TSLOBOD
209;3;SAMSUNG A300;26.06.2002;TSLOBOD
210;3;SAMSUNG R200;26.06.2002;TSLOBOD
211;3;SAMSUNG R210;26.06.2002;TSLOBOD
212;3;SAMSUNG N400;26.06.2002;TSLOBOD
213;3;SAGEM RC815;26.06.2002;TSLOBOD
214;3;SAGEM RC815;26.06.2002;TSLOBOD
215;3;SIEMENS SL45;26.06.2002;TSLOBOD
216;3;SIEMENS me45;26.06.2002;TSLOBOD
217;3;SIEMENS s45;26.06.2002;TSLOBOD
218;3;SIEMENS S35;26.06.2002;TSLOBOD
219;3;SIEMENS C45;26.06.2002;TSLOBOD
220;3;SIEMENS m35;26.06.2002;TSLOBOD
221;3;SIEMENS m35i;26.06.2002;TSLOBOD
222;3;SIEMENS c35;26.06.2002;TSLOBOD
223;3;SIEMENS c35i;26.06.2002;TSLOBOD
224;3;SIEMENS C35;26.06.2002;TSLOBOD
225;3;SIEMENS a40;26.06.2002;TSLOBOD
226;4;ALCATEL-700;26.06.2002;TSLOBOD
227;4;ALCATEL-500;26.06.2002;TSLOBOD
228;4;ALCATEL-501;26.06.2002;TSLOBOD
229;4;ALCATEL-310 ;26.06.2002;TSLOBOD
230;4;ALCATEL-302;26.06.2002;TSLOBOD
231;4;ALCATEL-301;26.06.2002;TSLOBOD
232;4;ALCATEL-511;26.06.2002;TSLOBOD
233;4;ERICSSON R380;26.06.2002;TSLOBOD
234;4;ERICSSON R320S;26.06.2002;TSLOBOD
235;4;ERICSON t39m;26.06.2002;TSLOBOD
236;4;ERICSSON t29S;26.06.2002;TSLOBOD
237;4;ERICSSON T20S;26.06.2002;TSLOBOD
238;4;ERICSSON T28s;26.06.2002;TSLOBOD
239;4;ERICSSON T18s;26.06.2002;TSLOBOD
240;4;ERICSSON R310S;26.06.2002;TSLOBOD
241;4;ERICSSON A2618s;26.06.2002;TSLOBOD
242;4;ERICSSON A1018;26.06.2002;TSLOBOD
243;4;MOTOROLA V66;26.06.2002;TSLOBOD
244;4;MOTOROLA V3690;26.06.2002;TSLOBOD
245;4;MOTOROLA v50;26.06.2002;TSLOBOD
246;4;MOTOROLA t280;26.06.2002;TSLOBOD
247;4;MOTOROLA L7089;26.06.2002;TSLOBOD
248;4;MOTOROLA P7389;26.06.2002;TSLOBOD
249;4;MOTOROLA TI 250;26.06.2002;TSLOBOD
250;4;MOTOROLA t192;26.06.2002;TSLOBOD
251;4;MOTOROLA V2288;26.06.2002;TSLOBOD
252;4;MOTOROLA V3688;26.06.2002;TSLOBOD
253;4;NOKIA 9210 +;26.06.2002;TSLOBOD
254;4;NOKIA 9210 Comm;26.06.2002;TSLOBOD
255;4;NOKIA-8890;26.06.2002;TSLOBOD
256;4;NOKIA-8850 ;26.06.2002;TSLOBOD
257;4;NOKIA 9110;26.06.2002;TSLOBOD
258;4;NOKIA 8310;26.06.2002;TSLOBOD
259;4;NOKIA 6510;26.06.2002;TSLOBOD
260;4;NOKIA 6310;26.06.2002;TSLOBOD
261;4;NOKIA 6250;26.06.2002;TSLOBOD
262;4;NOKIA 8210;26.06.2002;TSLOBOD
263;4;NOKIA 5510;26.06.2002;TSLOBOD
264;4;NOKIA-7110 ;26.06.2002;TSLOBOD
265;4;NOKIA-6210 ;26.06.2002;TSLOBOD
266;4;NOKIA 5210;26.06.2002;TSLOBOD
267;4;NOKIA 3210;26.06.2002;TSLOBOD
268;4;NOKIA-3310 ;26.06.2002;TSLOBOD
269;4;NOKIA-8810 ;26.06.2002;TSLOBOD
270;4;NOKIA 6150;26.06.2002;TSLOBOD
271;4;NOKIA 8110;26.06.2002;TSLOBOD
272;4;NOKIA 5110;26.06.2002;TSLOBOD
273;4;PANASONIC GD-92;26.06.2002;TSLOBOD
274;4;PANASONIC GD-93;26.06.2002;TSLOBOD
275;4;PANASONIC GD-52;26.06.2002;TSLOBOD
276;4;PANASONIC GD-75;26.06.2002;TSLOBOD
277;4;PANASONIC GD-95;26.06.2002;TSLOBOD
278;4;PHILIPS XENIUM;26.06.2002;TSLOBOD
279;4;PHILIPS OZEO;26.06.2002;TSLOBOD
280;4;PHILLIPS SAVVY TCD128;26.06.2002;TSLOBOD
281;4;PHILIPS GENIE;26.06.2002;TSLOBOD
282;4;PHILIPS DIGA;26.06.2002;TSLOBOD
283;4;SAMSUNG A400;26.06.2002;TSLOBOD
284;4;SAMSUNG A300;26.06.2002;TSLOBOD
285;4;SAMSUNG R200;26.06.2002;TSLOBOD
286;4;SAMSUNG R210;26.06.2002;TSLOBOD
287;4;SAMSUNG N400;26.06.2002;TSLOBOD
288;4;SAGEM RC815;26.06.2002;TSLOBOD
289;4;SAGEM RC815;26.06.2002;TSLOBOD
290;4;SIEMENS SL45;26.06.2002;TSLOBOD
291;4;SIEMENS me45;26.06.2002;TSLOBOD
292;4;SIEMENS s45;26.06.2002;TSLOBOD
293;4;SIEMENS S35;26.06.2002;TSLOBOD
294;4;SIEMENS C45;26.06.2002;TSLOBOD
295;4;SIEMENS m35;26.06.2002;TSLOBOD
296;4;SIEMENS m35i;26.06.2002;TSLOBOD
297;4;SIEMENS c35;26.06.2002;TSLOBOD
298;4;SIEMENS c35i;26.06.2002;TSLOBOD
299;4;SIEMENS C35;26.06.2002;TSLOBOD
300;4;SIEMENS a40;26.06.2002;TSLOBOD
301;5;ALCATEL-700;26.06.2002;TSLOBOD
302;5;ALCATEL-500;26.06.2002;TSLOBOD
303;5;ALCATEL-501;26.06.2002;TSLOBOD
304;5;ALCATEL-310 ;26.06.2002;TSLOBOD
305;5;ALCATEL-302;26.06.2002;TSLOBOD
306;5;ALCATEL-301;26.06.2002;TSLOBOD
307;5;ALCATEL-511;26.06.2002;TSLOBOD
308;5;ERICSSON R380;26.06.2002;TSLOBOD
309;5;ERICSSON R320S;26.06.2002;TSLOBOD
310;5;ERICSON t39m;26.06.2002;TSLOBOD
311;5;ERICSSON t29S;26.06.2002;TSLOBOD
312;5;ERICSSON T20S;26.06.2002;TSLOBOD
313;5;ERICSSON T28s;26.06.2002;TSLOBOD
314;5;ERICSSON T18s;26.06.2002;TSLOBOD
315;5;ERICSSON R310S;26.06.2002;TSLOBOD
316;5;ERICSSON A2618s;26.06.2002;TSLOBOD
317;5;ERICSSON A1018;26.06.2002;TSLOBOD
318;5;MOTOROLA V66;26.06.2002;TSLOBOD
319;5;MOTOROLA V3690;26.06.2002;TSLOBOD
320;5;MOTOROLA v50;26.06.2002;TSLOBOD
321;5;MOTOROLA t280;26.06.2002;TSLOBOD
322;5;MOTOROLA L7089;26.06.2002;TSLOBOD
323;5;MOTOROLA P7389;26.06.2002;TSLOBOD
324;5;MOTOROLA TI 250;26.06.2002;TSLOBOD
325;5;MOTOROLA t192;26.06.2002;TSLOBOD
326;5;MOTOROLA V2288;26.06.2002;TSLOBOD
327;5;MOTOROLA V3688;26.06.2002;TSLOBOD
328;5;NOKIA 9210 +;26.06.2002;TSLOBOD
329;5;NOKIA 9210 Comm;26.06.2002;TSLOBOD
330;5;NOKIA-8890;26.06.2002;TSLOBOD
331;5;NOKIA-8850 ;26.06.2002;TSLOBOD
332;5;NOKIA 9110;26.06.2002;TSLOBOD
333;5;NOKIA 8310;26.06.2002;TSLOBOD
334;5;NOKIA 6510;26.06.2002;TSLOBOD
335;5;NOKIA 6310;26.06.2002;TSLOBOD
336;5;NOKIA 6250;26.06.2002;TSLOBOD
337;5;NOKIA 8210;26.06.2002;TSLOBOD
338;5;NOKIA 5510;26.06.2002;TSLOBOD
339;5;NOKIA-7110 ;26.06.2002;TSLOBOD
340;5;NOKIA-6210 ;26.06.2002;TSLOBOD
341;5;NOKIA 5210;26.06.2002;TSLOBOD
342;5;NOKIA 3210;26.06.2002;TSLOBOD
343;5;NOKIA-3310 ;26.06.2002;TSLOBOD
344;5;NOKIA-8810 ;26.06.2002;TSLOBOD
345;5;NOKIA 6150;26.06.2002;TSLOBOD
346;5;NOKIA 8110;26.06.2002;TSLOBOD
347;5;NOKIA 5110;26.06.2002;TSLOBOD
348;5;PANASONIC GD-92;26.06.2002;TSLOBOD
349;5;PANASONIC GD-93;26.06.2002;TSLOBOD
350;5;PANASONIC GD-52;26.06.2002;TSLOBOD
351;5;PANASONIC GD-75;26.06.2002;TSLOBOD
352;5;PANASONIC GD-95;26.06.2002;TSLOBOD
353;5;PHILIPS XENIUM;26.06.2002;TSLOBOD
354;5;PHILIPS OZEO;26.06.2002;TSLOBOD
355;5;PHILLIPS SAVVY TCD128;26.06.2002;TSLOBOD
356;5;PHILIPS GENIE;26.06.2002;TSLOBOD
357;5;PHILIPS DIGA;26.06.2002;TSLOBOD
358;5;SAMSUNG A400;26.06.2002;TSLOBOD
359;5;SAMSUNG A300;26.06.2002;TSLOBOD
360;5;SAMSUNG R200;26.06.2002;TSLOBOD
361;5;SAMSUNG R210;26.06.2002;TSLOBOD
362;5;SAMSUNG N400;26.06.2002;TSLOBOD
363;5;SAGEM RC815;26.06.2002;TSLOBOD
364;5;SAGEM RC815;26.06.2002;TSLOBOD
365;5;SIEMENS SL45;26.06.2002;TSLOBOD
366;5;SIEMENS me45;26.06.2002;TSLOBOD
367;5;SIEMENS s45;26.06.2002;TSLOBOD
368;5;SIEMENS S35;26.06.2002;TSLOBOD
369;5;SIEMENS C45;26.06.2002;TSLOBOD
370;5;SIEMENS m35;26.06.2002;TSLOBOD
371;5;SIEMENS m35i;26.06.2002;TSLOBOD
372;5;SIEMENS c35;26.06.2002;TSLOBOD
373;5;SIEMENS c35i;26.06.2002;TSLOBOD
374;5;SIEMENS C35;26.06.2002;TSLOBOD
375;5;SIEMENS a40;26.06.2002;TSLOBOD


