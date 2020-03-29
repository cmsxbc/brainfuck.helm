{{/* vim: set filetype=mustache: */}}

{{- define "bf.run" -}}
{{-   $env := dict "s" (splitList "" $.program) "i" $.input "ii" 0 -}}
{{-   $_ := set $env "ma" (default 1000000 (get $ "maxActions")) -}}
{{-   $_ := set $env "el" (default 100 (get $ "everyLoop")) -}}
{{-   template "bf._init" $env -}}
{{-   template "bf._check_program" $env -}}
{{-   template "bf._run" $env -}}
{{- end -}}

{{- define "bf._init" -}}
{{-   $_ := set $ "m" dict -}}
{{-   $_ := set $ "p" 0 -}}
{{-   $_ := set $ "b" list -}}
{{-   $_ := set $ "sp" 0 -}}
{{-   $_ := set $ "l" (int64 (len $.s)) -}}
{{-   $_ := set $ "il" (int64 (len $.i)) -}}
{{-   $_ := set $ "mcs" (list "<" ">" "[" "]" "+" "-" "." ",") -}}
{{-   $_ := set $ "ac" 0 -}}
{{- end -}}

{{- define "bf._check_program" -}}
{{-   $_ := set $ "__cp_tmp_c" 0 -}}
{{-   range $i, $t := $.s -}}
{{-     if eq $t "[" -}}
{{-       $_ := add1 $.__cp_tmp_c | set $ "__cp_tmp_c" -}}
{{-     else if eq $t "]" -}}
{{-       $_ := sub $.__cp_tmp_c 1 | set $ "__cp_tmp_c" -}}
{{-     end -}}
{{-     if lt $.__cp_tmp_c 0 -}}
{{-       fail (printf "not matched \"[]\" @char:%d" (add1 $i)) -}}
{{-     end -}}
{{-   end -}}
{{-   $_ := unset $ "__cp_tmp_c" -}}
{{- end -}}

{{/*
the helm has 100000 maximum template depth 
*/}}
{{- define "bf._run" -}}
{{-   range $i := until $.el -}}
{{-     if (gt ($.l) ($.sp)) -}}
{{-       $_ := add1 $.ac | set $ "ac" -}}
{{-       template "bf._action" $ -}}
{{-     end -}}
{{-   end -}}
{{-   if ge $.ac $.ma -}}
{{-     set $ "error_msg" "may be there is a deadloop" | include "bf.__fail" -}}
{{-   end -}}
{{-   if (gt ($.l) ($.sp)) -}}
{{-     template "bf._run" $ -}}
{{-   end -}}
{{- end -}}

{{- define "bf._action" -}}
{{-   if hasKey $ "_skip2]" -}}
{{-     if get $ "_skip2]" -}}
{{-       include "bf._skip2]" $ -}}
{{-     end -}}
{{-   end -}}
{{-   if (gt ($.l) ($.sp)) -}}
{{-     if has (index $.s $.sp) $.mcs -}}
{{-       $name := printf "bf._token_%s" (index $.s $.sp) -}}
{{-       include $name $ -}}
{{-     end -}}
{{-   end -}}
{{-   $_ := add 1 $.sp | set $ "sp" -}}
{{- end -}}

{{- define "bf._skip2]" -}}
{{-   if ne (index $.s $.sp) "]" -}}
{{-     $_ := add 1 $.sp | set $ "sp" -}}
{{-     include "bf._skip2]" $ -}}
{{-   else -}}
{{-     $_ := unset $ "_skip2]" -}}
{{-   end -}}
{{- end -}}

{{- define "bf._token_>" -}}
{{-   $_ := add1 $.p | set $ "p" -}}
{{- end -}}

{{- define "bf._token_<" -}}
{{-   $_ := sub $.p 1 | set $ "p" -}}
{{- end -}}

{{- define "bf._token_+" -}}
{{-   $p := toString $.p -}}
{{-   if hasKey $.m $p -}}
{{-     $_ := get $.m $p | add1 | set $.m $p -}}
{{-   else -}}
{{-     $_ := set $.m $p 1 -}}
{{-   end -}}
{{- end -}}

{{- define "bf._token_-" -}}
{{-   $p := toString $.p -}}
{{-   if hasKey $.m $p -}}
{{-     $_ := sub (get $.m $p) 1 | set $.m $p -}}
{{-   else -}}
{{-     $_ := set $.m $p -1 -}}
{{-   end -}}
{{- end -}}

{{- define "bf._token_." -}}
{{-   $p := toString $.p -}}
{{-   if hasKey $.m $p -}}
{{-     printf "%c" (get $.m $p) -}}
{{-   else -}}
{{-     printf "%c" 0 -}}
{{-   end -}}
{{- end -}}

{{- define "bf._token_," -}}
{{-   $p := toString $.p -}}
{{-   if ge $.ii $.il  -}}
{{-     set $ "error_msg" "There is not enough input" | include "bf.__fail" -}}
{{-   end -}}
{{-   $_ := set $.m $p (int (index $.i $.ii)) -}}
{{-   $_ := add1 $.ii | set $ "ii" -}}
{{- end -}}

{{- define "bf._token_[" -}}
{{-   $p := toString $.p -}}
{{-   if eq (default 0 (get $.m $p)) 0 -}}
{{-     $_ := set $ "_skip2]" true -}}
{{-   else -}}
{{-     $_ := prepend $.b $.sp | set $ "b" -}}
{{-   end -}}
{{- end -}}

{{- define "bf._token_]" -}}
{{-   $p := toString $.p -}}
{{-   if ne (default 0 (get $.m $p)) 0 -}}
{{-     if empty $.b -}}
{{-       set $ "error_msg" "maybe there is something wrong in your program" | include "bf.__fail" -}}
{{-     end -}}
{{-     $_ := first $.b | set $ "sp" -}}
{{-     $_ := rest $.b | set $ "b" -}}
{{-     include "bf._token_[" $ -}}
{{-   else -}}
{{-     $_ := rest $.b | set $ "b" -}}
{{-   end -}}
{{- end -}}

{{- define "bf.__fail" -}}
{{-   omit $ "s" "mcs" "error_msg" | toYaml | printf "\nerror:%s\ntrackback:\n%s" (get $ "error_msg") | fail -}}
{{- end -}}

{{- define "bf.__debug" -}}
{{-   omit $ "s" "mcs" "error_msg" | toYaml | printf "%s" | set $ "last_call" -}}
{{- end -}}

{{- define "bf.__debug_1" -}}
{{-   omit $ "s" "mcs" "last_call" "error_msg" | toYaml | printf "%s" | set $ "last_call" -}}
{{- end -}}
