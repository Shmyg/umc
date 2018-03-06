/*
Program for cleaning file with model names and IMEIs from SAP
Removes all cyrillic symbols, leading and trailing spaces
and prepares file for sqlloader.
Created by Klyam 17.07.2002
Some minor changes and comments added by Shmyg 17.07.2002
*/

#include <stdio.h>

char *const input_file = "/tmp/phones.txt";
char *const output_file = "/tmp/phones.dat";

// Function for removing cyrilling characters
void clean_russian_characters(char * str)
{
    int i = 0;
    while(str[i] != 0)
    {
        if(!isascii(str[i]))
            str[i] = ' ';
        ++i;
    }
}

// Function for removing leading spaces
void clean_leading_spaces(char * str, char * dest)
{
    int start = 0;
    int i = 0;
    int j = 0;

    while(str[i] != 0)
    {
        if(!start && isspace(str[i]))
        {
            ++i;
            continue;
        }

        start = 1;
        dest[j++] = str[i++];
    }
}

// Function for removing trailing spaces
void clean_trailing_spaces(char * str, char * dest)
{
    int i = 0;
    
    if(strlen(str) == 0)
    {
        dest[0] = 0;
        return;
    }
    
    i = strlen(str) - 1;

    while((i >= 0) && isspace(str[i]))
    {
		--i;
    }

    strncpy(dest, str, i);
    dest[i+1] = 0;
        
}

int main(int argc, char *argv[])
{
    FILE *in_fd = NULL;
    FILE *out_fd = NULL;

        char    model_name[41] = {0};
        char    imei[19] = {0};

        char data[60] = {0};

        in_fd = fopen(input_file, "rt");
        if(in_fd == NULL)
        {
            fprintf(stderr, "Can't open input file for reading.\n");
            exit(1);
        }

        out_fd = fopen(output_file, "wt");
        if(out_fd == NULL)
        {
            fclose(out_fd);
            fprintf(stderr, "Cant open output file for writing.\n");
            exit(2);
        }

        while (fgets(data, 60, in_fd) != 0)
        {
            int len = (40 > strlen(data) ? strlen(data) : 40);
            char buffer[41] = {0};

            memset(model_name, 0, sizeof(model_name));
            strncpy(model_name, data, len);

            
            clean_russian_characters(model_name);
            clean_leading_spaces(model_name, buffer);
            strcpy(model_name, buffer);
            clean_trailing_spaces(model_name, buffer);
            strcpy(model_name, buffer);

            len = ((18 > (strlen(data) - 40)) ? (strlen(data) - 40) : 18);

            memset(imei, 0, sizeof(imei));
            strncpy(imei, &data[40], len);

            if(imei[strlen(imei) - 1] == '\n')
                imei[strlen(imei) - 1] = 0;

            fprintf(out_fd, "%s:%s\n", model_name, imei);

        }

        fclose(in_fd);
        fclose(out_fd);
        
        return 0;
}
