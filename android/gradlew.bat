@ECHO OFF
SET APP_HOME=%~dp0
SET WRAPPER_JAR=%APP_HOME%gradle\wrapper\gradle-wrapper.jar
IF NOT EXIST "%WRAPPER_JAR%" SET WRAPPER_JAR=C:\flutter\bin\cache\artifacts\gradle_wrapper\gradle\wrapper\gradle-wrapper.jar
java -classpath "%WRAPPER_JAR%" org.gradle.wrapper.GradleWrapperMain %*
