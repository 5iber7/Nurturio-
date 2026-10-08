// Accept a constrained JPEG header, reject oversized dimensions and malformed segments.
export function jpegSize(bytes:Uint8Array):{width:number;height:number}|null{
  if(bytes.length<4||bytes[0]!==255||bytes[1]!==216)return null;
  let i=2;
  while(i+3<bytes.length){if(bytes[i]!==255)return null;const marker=bytes[i+1];i+=2;
    if(marker===217||marker===218)return null;
    const length=(bytes[i]<<8)|bytes[i+1];if(length<2||i+length>bytes.length)return null;
    if([192,193,194].includes(marker)&&length>=8){const height=(bytes[i+3]<<8)|bytes[i+4],width=(bytes[i+5]<<8)|bytes[i+6];return width>0&&height>0?{width,height}:null;}
    i+=length;
  }return null;
}
