# Robocopy-WindowsShadowCopy
Recuperar información de Windows Shadow Copy con Robocopy

Seguro que te ha pasado más de una vez. Quieres recuperar documentación de las Shadow Copies de Windows, pero un directorio es demasiado largo.
Con la herramienta Robocopy i un pequeño truco para acceder a las shadow copies podras recuperarlos sin problemas.

1. Como crear un link al directorio que nos interesa.
            * http://blog.johnwray.com/post/2016/05/06/robocopy-from-shadowcopies-previous-versions
2. Robocopy link:
            * https://es.wikipedia.org/wiki/Robocopy
3. You want to list all of the shadow copies available. Run this command to create a text file.
    * `vssadmin list shadows > d:\temp\shadows.txt`
4. We are looking for the shadow copy volume name in the shadows.txt
5. Create link
    * `mklink /d D:\shadow \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy416\`
    * D:\shadow => name of link
    * \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy416\ => Shadow xopy volume name. Caution, you add the '\\' at the end
6. Execute Robocopy
      * `robocopy /MT:16 "\\<server>\shadow$\OTC-IT\D_Drive\IT-Dept\Common" "\\<server>\IT-Dept\Common" /E /XC /XN /XO /W:0 /R:0`
7. Delete shodow link
      * rmdir d:\shadow
