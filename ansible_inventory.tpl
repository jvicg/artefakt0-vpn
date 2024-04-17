[servers]
%{ for instance in instances ~}
${instance.tags.Name} ansible_host=${instance.public_dns}
%{ endfor ~}
